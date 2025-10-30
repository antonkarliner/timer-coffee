import 'dart:convert';
import 'dart:io';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/services/ocr/ocr_service.dart';
import 'package:coffee_timer/services/ocr/native_ocr_service.dart';
import 'package:coffee_timer/services/ocr/ocr_fallback_handler.dart';
import 'package:coffee_timer/utils/images/image_resizer.dart';
import 'package:coffee_timer/services/clients/beans_label_parser_client.dart';
import 'package:coffee_timer/utils/device_profiler.dart';
import 'package:coffee_timer/utils/images/image_preprocessor.dart';
import 'package:coffee_timer/utils/ocr_performance_monitor.dart';
import 'package:coffee_timer/utils/ocr_performance_history.dart';
import 'package:coffee_timer/models/image_processing_result.dart';

// Simple timing helper for console instrumentation
class _StopwatchX {
  final Stopwatch _sw = Stopwatch()..start();
  int stopMs() {
    _sw.stop();
    return _sw.elapsedMilliseconds;
  }
}

/// A controller that orchestrates the "image flow" for New Beans:
/// - first-time popup logic (delegated to caller)
/// - image selection (camera/gallery), optional multi-shot camera loop
/// - preview/selection removal (delegated to caller UI)
/// - resize + base64 encode
/// - invoke Edge Function through BeansLabelParserClient
///
/// This controller keeps business logic separated from Widget build trees.
/// The UI (dialogs/sheets) should be implemented by the caller and wired via the
/// provided callbacks.
class NewBeansImageController {
  final ImagePicker _picker = ImagePicker();
  final BeansLabelParserClient _client;
  final OcrService _ocrService = NativeOcrService();
  late final OcrFallbackHandler _fallbackHandler;
  final OcrPerformanceMonitor _monitor = OcrPerformanceMonitor();
  final OcrPerformanceHistory _history = OcrPerformanceHistory.instance;

  // OCR gating state (per start() session)
  bool _ocrDisabledForSession = false;

  // Thresholds (ms)
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5MB threshold

  // Centralized console logging for this controller
  // Prefix helps filter in aggregated logs
  // Example: [NewBeansOCR] message
  void _log(String msg) {
    AppLogger.debug('[NewBeansOCR] $msg');
  }

  NewBeansImageController({
    required SupabaseClient supabaseClient,
  }) : _client = BeansLabelParserClient(supabaseClient) {
    // Initialize fallback handler with native OCR service and cloud client
    _fallbackHandler = OcrFallbackHandler(
      nativeOcrService: _ocrService,
      cloudClient: _client,
      maxRetryAttempts: 3,
      retryDelaysMs: const [1000, 2000, 4000], // 1s, 2s, 4s
    );

    // Initialize performance monitoring
    _monitor.initialize();
    // Initialize performance history
    _history.initialize();
  }

  /// Starts the flow for selecting images (camera or gallery) and parsing them.
  /// The controller does not present UI itself. Instead, it relies on the caller to:
  /// - ask the user to choose the source (camera/gallery) via `onChooseSource`.
  /// - show preview sheets/dialogs via `onShowPreview`.
  /// - show error dialogs via `onError`.
  ///
  /// Required callbacks:
  /// - onLoading(bool isLoading)
  /// - onData(Map<String, dynamic> parsed)
  /// - onError(String message)
  /// - onShowPreview(List<XFile> images, void Function(List<XFile>) onConfirm, void Function() onBackToSelection)
  /// - onChooseSource(Future<ImageSource?> Function() chooser) - see defaultChooser example below.
  Future<void> start({
    required BuildContext context,
    required String locale,
    required void Function(bool) onLoading,
    required void Function(Map<String, dynamic>) onData,
    required void Function(String) onError,
    required Future<ImageSource?> Function() onChooseSource,
    required Future<void> Function(
      List<XFile> images,
      Future<void> Function(List<XFile>) onConfirm,
      Future<void> Function() onBackToSelection,
    ) onShowPreview,
    String? userId,
    bool isFirstTime = false,
  }) async {
    // Ask user for source (camera/gallery)
    final source = await onChooseSource();
    if (source == null) return;

    try {
      // Pick images
      final images = await _pickImages(source);
      if (images.isEmpty) return;

      // Limit to 2 images
      final limited = images.take(2).toList();

      // Present preview UI to allow removing/reselecting
      await onShowPreview(
        limited,
        (confirmed) async {
          // Process confirmed images
          await _processAndParse(
            context: context,
            images: confirmed,
            locale: locale,
            userId: userId,
            onLoading: onLoading,
            onData: onData,
            onError: onError,
            isFirstTime: isFirstTime,
          );
        },
        () async {
          // go back to selection → recurse into start
          await start(
            context: context,
            locale: locale,
            onLoading: onLoading,
            onData: onData,
            onError: onError,
            onChooseSource: onChooseSource,
            onShowPreview: onShowPreview,
            userId: userId,
            isFirstTime: isFirstTime,
          );
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Pick up to 2 images. For camera, supports a multi-shot loop (ask user whether to take another),
  /// mirroring original behavior from NewBeansScreen.
  Future<List<XFile>> _pickImages(ImageSource source) async {
    if (source == ImageSource.camera) {
      final List<XFile> shots = [];
      while (shots.length < 2) {
        final XFile? image =
            await _picker.pickImage(source: ImageSource.camera);
        if (image != null) {
          shots.add(image);
        }
        if (shots.length < 2) {
          // Ask user if they'd like to take another photo. The controller itself doesn't own UI,
          // so callers must provide a dialog in onChooseMoreCameraShots.
          final bool takeAnother =
              await _onAskTakeAnotherPhoto?.call() ?? false;
          if (!takeAnother) break;
        }
      }
      return shots;
    } else {
      if (kIsWeb) {
        final XFile? image =
            await _picker.pickImage(source: ImageSource.gallery);
        return image != null ? [image] : [];
      } else {
        final images = await _picker.pickMultiImage(imageQuality: 50);
        return images;
      }
    }
  }

  /// Callback used internally to ask the user if they want to take another camera shot (for multi-shot loop).
  /// Must be wired by the caller via [setAskTakeAnotherPhotoCallback].
  Future<bool> Function()? _onAskTakeAnotherPhoto;

  /// Set the callback used to ask the user to take another photo when using the camera.
  void setAskTakeAnotherPhotoCallback(Future<bool> Function() cb) {
    _onAskTakeAnotherPhoto = cb;
  }

  // Enhanced static capability gate using DeviceProfiler:
  // - Skip OCR on Web
  // - Use DeviceProfiler to check device capabilities
  // - Check adaptive mode selection based on performance history
  // - Runtime timing guard will still disable if too slow
  Future<bool> _passesStaticOcrGate() async {
    if (kIsWeb) return false;

    try {
      // Use DeviceProfiler to determine if device is capable
      final isLowEnd = await DeviceProfiler.isLowEndDevice;
      final passesDeviceGate = !isLowEnd;

      // Check adaptive mode selection based on performance history
      final shouldAttemptNative = _history.shouldAttemptNativeOcr();
      final passesAdaptiveGate = shouldAttemptNative;

      final passesGate = passesDeviceGate && passesAdaptiveGate;

      _log(
          'OCR gate check: isLowEnd=$isLowEnd, passesDeviceGate=$passesDeviceGate, '
          'shouldAttemptNative=$shouldAttemptNative, passesAdaptiveGate=$passesAdaptiveGate, '
          'finalGate=$passesGate');

      // Log if adaptive mode is forcing cloud mode
      if (passesDeviceGate && !passesAdaptiveGate) {
        _log(
            'Adaptive mode selection is forcing cloud mode due to performance history');
      }

      return passesGate;
    } catch (e) {
      _log('Error in OCR gate check: $e, defaulting to false');
      return false;
    }
  }

  /// Determines the appropriate max image size based on device capabilities
  /// Returns 800px for low-end devices, 1024px for capable devices
  Future<int> _getDeviceAwareMaxImageSize() async {
    try {
      final isLowEnd = await DeviceProfiler.isLowEndDevice;
      final maxSize = isLowEnd ? 800 : 1024;
      _log('Device-aware image sizing: isLowEnd=$isLowEnd, maxSize=$maxSize');
      return maxSize;
    } catch (e) {
      _log('Error determining device-aware image size: $e, defaulting to 1024');
      return 1024; // Default to capable device size on error
    }
  }

  /// Process a single image in parallel (for use with Future.wait)
  Future<ImageProcessingResult> _processSingleImageParallel(
    XFile image,
    int maxImageSize,
    bool ocrDisabled,
    int imageIndex,
  ) async {
    final swTotal = _StopwatchX();
    final fileName = image.path.split('/').last;
    final performanceMetrics = <String, dynamic>{};

    try {
      _logMemoryUsage(
          'Starting parallel image processing for image ${imageIndex + 1}');

      String? ocrText;
      String base64Image;

      if (!kIsWeb) {
        final file = File(image.path);

        // Check file size before processing
        final fileSize = await file.length();
        if (fileSize > _maxFileSizeBytes) {
          _log(
              'Skipping large image: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB exceeds threshold of ${(_maxFileSizeBytes / 1024 / 1024).toStringAsFixed(2)}MB');
          return ImageProcessingResult.failure(
            fileName: fileName,
            imageIndex: imageIndex,
            error: 'Image size exceeds threshold',
            performanceMetrics: {'fileSize': fileSize, 'skipped': true},
          );
        }

        // Perform OCR if not disabled
        if (!ocrDisabled) {
          // Apply image preprocessing before OCR (grayscale only, contrast disabled)
          final preprocessSw = _StopwatchX();
          final preprocessedFile = await ImagePreprocessor.preprocessForOcr(
            file,
            enableContrastEnhancement: false,
          );
          final preprocessMs = preprocessSw.stopMs();
          performanceMetrics['preprocessMs'] = preprocessMs;

          _log(
              'Image preprocessing completed in ${preprocessMs}ms for $fileName');

          // Perform native OCR directly
          final ocrSw = _StopwatchX();
          ocrText = await _ocrService.recognizeText(preprocessedFile ?? file);
          final ocrMs = ocrSw.stopMs();
          performanceMetrics['ocrMs'] = ocrMs;

          _log('Native OCR completed in ${ocrMs}ms: chars=${ocrText.length}');

          // Clean up preprocessed file
          if (preprocessedFile != null) {
            try {
              if (preprocessedFile.path != file.path) {
                await preprocessedFile.delete();
                _log('Cleaned up preprocessed file: ${preprocessedFile.path}');
              }
            } catch (e) {
              _log('Error cleaning up preprocessed file: $e');
            }
          }

          // Force garbage collection after OCR to free memory
          _forceGarbageCollection();
        }

        // Downscale before sending to reduce bandwidth while keeping label legibility
        final swResize = _StopwatchX();
        final resized = await ImageResizer.resizeToMaxSize(file, maxImageSize);
        final resizeMs = swResize.stopMs();
        performanceMetrics['resizeMs'] = resizeMs;

        // Start performance monitoring for image resize
        final endResizeMonitoring = await _monitor.startOperation(
          OcrOperationType.imageResize,
          imageSizeBytes: await file.length(),
        );

        // Optimized base64 encoding with memory management
        final swEncode = _StopwatchX();
        base64Image = await _encodeToBase64Optimized(resized);
        final encodeMs = swEncode.stopMs();
        performanceMetrics['encodeMs'] = encodeMs;

        // Start performance monitoring for base64 encoding
        final endEncodeMonitoring = await _monitor.startOperation(
          OcrOperationType.base64Encoding,
          imageSizeBytes: resized.lengthSync(),
        );

        _log(
            'Resize+encode done in ${resizeMs}ms+${encodeMs}ms for $fileName (max_size=${maxImageSize}px)');

        // Record performance metrics
        endResizeMonitoring(
          success: true,
          additionalData: {
            'fileName': fileName,
            'maxImageSize': maxImageSize,
            'originalSize': await file.length(),
            'resizedSize': await resized.length(),
            'parallel': true,
          },
        );

        endEncodeMonitoring(
          success: true,
          additionalData: {
            'fileName': fileName,
            'encodedSize': base64Image.length,
            'parallel': true,
          },
        );

        // Force garbage collection after image processing
        _forceGarbageCollection();
      } else {
        // Web fallback: no OCR (native plugin is not supported on web)
        final swRead = _StopwatchX();

        // Check file size before processing
        final fileSize = await image.length();
        if (fileSize > _maxFileSizeBytes) {
          _log(
              'Skipping large web image: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB exceeds threshold of ${(_maxFileSizeBytes / 1024 / 1024).toStringAsFixed(2)}MB');
          return ImageProcessingResult.failure(
            fileName: fileName,
            imageIndex: imageIndex,
            error: 'Image size exceeds threshold',
            performanceMetrics: {'fileSize': fileSize, 'skipped': true},
          );
        }

        base64Image = await _encodeXFileToBase64Optimized(image);
        final readMs = swRead.stopMs();
        performanceMetrics['readMs'] = readMs;

        _log('Web read+encode done in ${readMs}ms for $fileName');

        // Force garbage collection after web image processing
        _forceGarbageCollection();
      }

      performanceMetrics['totalMs'] = swTotal.stopMs();
      performanceMetrics['parallel'] = true;

      return ImageProcessingResult.success(
        base64Image: base64Image,
        fileName: fileName,
        imageIndex: imageIndex,
        ocrText: ocrText,
        performanceMetrics: performanceMetrics,
      );
    } catch (e, st) {
      _log('Error during parallel image processing for $fileName: $e\n$st');
      return ImageProcessingResult.failure(
        fileName: fileName,
        imageIndex: imageIndex,
        error: e.toString(),
        performanceMetrics: {
          'totalMs': swTotal.stopMs(),
          'parallel': true,
          'error': true,
        },
      );
    }
  }

  /// Determine the maximum number of concurrent operations based on device capabilities
  Future<int> _getMaxConcurrentOperations() async {
    try {
      final isLowEnd = await DeviceProfiler.isLowEndDevice;
      // Limit concurrent operations on low-end devices to prevent memory pressure
      return isLowEnd ? 1 : 2;
    } catch (e) {
      _log('Error determining max concurrent operations: $e, defaulting to 1');
      return 1; // Conservative fallback
    }
  }

  Future<void> _processAndParse({
    required BuildContext context,
    required List<XFile> images,
    required String locale,
    required String? userId,
    required void Function(bool) onLoading,
    required void Function(Map<String, dynamic>) onData,
    required void Function(String) onError,
    bool isFirstTime = false,
  }) async {
    final swTotal = _StopwatchX();
    onLoading(true);
    try {
      _log(
          'Starting OCR + prepare. Images: ${images.length}, locale: $locale, userId: ${userId ?? 'anon'}, isFirstTime: $isFirstTime');

      // Initialize gating state per session
      // For first-time usage, always disable OCR to ensure better UX
      _ocrDisabledForSession =
          isFirstTime ? true : !(await _passesStaticOcrGate());

      // Determine device-aware image size
      final int maxImageSize = await _getDeviceAwareMaxImageSize();
      _log('Using device-aware max image size: ${maxImageSize}px');

      // Determine max concurrent operations based on device capabilities
      final int maxConcurrent = await _getMaxConcurrentOperations();
      _log('Using max concurrent operations: $maxConcurrent');

      if (_ocrDisabledForSession) {
        if (isFirstTime) {
          _log(
              'OCR disabled for first-time usage; sending images only for better UX.');
        } else {
          _log(
              'OCR disabled by device capability gate; will skip on-device OCR.');
        }
      }

      final prepSw = _StopwatchX();

      // Process images in parallel batches
      final List<ImageProcessingResult> results = [];

      if (images.length == 1 || maxConcurrent == 1) {
        // Sequential processing for single image or low-end devices
        _log('Using sequential processing');
        for (int idx = 0; idx < images.length; idx++) {
          final result = await _processSingleImageParallel(
            images[idx],
            maxImageSize,
            _ocrDisabledForSession,
            idx,
          );
          results.add(result);
        }
      } else {
        // Parallel processing for multiple images on capable devices
        _log('Using parallel processing');

        // Create processing futures for all images
        final futures = images.map((image) {
          final index = images.indexOf(image);
          return _processSingleImageParallel(
            image,
            maxImageSize,
            _ocrDisabledForSession,
            index,
          );
        }).toList();

        // Wait for all processing to complete
        results.addAll(await Future.wait(futures));
      }

      _log(
          'Prep complete in ${prepSw.stopMs()}ms. Processed ${results.length} images (ocr_enabled=${!_ocrDisabledForSession})');

      // Filter successful results and extract data
      final successfulResults = results.where((r) => r.success).toList();
      final base64Images = successfulResults.map((r) => r.base64Image).toList();
      final ocrSnippets = successfulResults
          .where((r) => r.hasOcrText)
          .map((r) => r.ocrText!)
          .toList();

      if (base64Images.isEmpty) {
        onLoading(false);
        _log('No images to process; aborting.');
        return;
      }

      final String ocrTextCombined =
          ocrSnippets.join('\n').replaceAll('\r\n', '\n').trim();

      // Decide mode client-side; send OCR text so server can choose text vs image.
      final mode = 'auto';
      final minTextChars = 120;

      // If OCR disabled for this session or OCR text empty, do not send text
      final String? ocrPayload =
          (_ocrDisabledForSession || ocrTextCombined.isEmpty)
              ? null
              : ocrTextCombined;

      // Explicitly log what we are sending to the Edge Function
      _log('Sending to Edge: mode=$mode, ocr_enabled=${ocrPayload != null}, '
          'ocr_chars=${ocrPayload?.length ?? 0}, images=${base64Images.length}, locale=$locale');
      // Add detailed logging to show OCR text content
      if (ocrPayload != null && ocrPayload.isNotEmpty) {
        _log('OCR text being sent to Edge: "${ocrPayload}"');
      } else {
        _log('No OCR text being sent to Edge (OCR disabled or empty)');
      }

      // Start performance monitoring for fallback operation
      final endFallbackMonitoring = await _monitor.startOperation(
        OcrOperationType.fallback,
        imageSizeBytes:
            base64Images.fold<int>(0, (sum, img) => sum + img.length),
      );

      final swEdge = _StopwatchX();
      final parsed = await _client.parseLabel(
        base64Images: base64Images,
        locale: locale, // keep locale as target translation language
        userId: userId,
        ocrText: ocrPayload,
        mode: mode,
        minTextChars: minTextChars,
      );
      final edgeMs = swEdge.stopMs();

      // Log meta if server returned it
      Map<String, dynamic>? serverMeta;
      try {
        serverMeta = parsed is Map<String, dynamic>
            ? parsed['meta'] as Map<String, dynamic>?
            : null;
        if (serverMeta is Map<String, dynamic>) {
          _log(
              'Server meta: decided_mode=${serverMeta['decided_mode']}, tokens_used=${serverMeta['tokens_used']}, '
              'limit=${serverMeta['token_limit']}, used_this_month=${serverMeta['tokens_used_this_month']}, '
              'model=${serverMeta['model_used']}, edge_total_ms=${serverMeta['execution_time_ms_total']}, '
              'edge_gemini_ms=${serverMeta['execution_time_ms_gemini']}, '
              'ocr_text_chars_sent=${serverMeta['ocr_text_chars']}, images_count_sent=${serverMeta['images_count']}');
        } else {
          _log(
              'No meta in response. Edge call time (client observed) = ${edgeMs}ms');
        }
      } catch (_) {
        _log(
            'Meta parse failed; Edge call time (client observed) = ${edgeMs}ms');
      }

      // Record fallback performance metrics
      endFallbackMonitoring(
        success: true,
        additionalData: {
          'imagesCount': base64Images.length,
          'ocrEnabled': ocrPayload != null,
          'ocrChars': ocrPayload?.length ?? 0,
          'locale': locale,
          'edgeExecutionTime': edgeMs,
          'serverMeta': serverMeta ?? {},
          'parallel': maxConcurrent > 1,
          'totalImages': images.length,
          'successfulImages': successfulResults.length,
          'failedImages': results.length - successfulResults.length,
        },
      );

      onLoading(false);
      _log('Total client flow time: ${swTotal.stopMs()}ms');
      onData(parsed);
    } catch (e, st) {
      onLoading(false);
      _log('Error during OCR/parse: $e\n$st');
      onError(e.toString());
    }
  }

  /// Optimized base64 encoding with memory management for File
  Future<String> _encodeToBase64Optimized(File file) async {
    try {
      final fileSize = await file.length();

      // For smaller files, use standard approach
      if (fileSize < 1024 * 1024) {
        // 1MB
        final bytes = await file.readAsBytes();
        final result = base64Encode(bytes);
        // Clear bytes from memory
        bytes.fillRange(0, bytes.length, 0);
        return result;
      } else {
        // For larger files, use chunked encoding
        return await _encodeToBase64InChunks(file);
      }
    } catch (e) {
      _log('Error in optimized base64 encoding: $e');
      // Fallback to standard encoding
      return base64Encode(await file.readAsBytes());
    }
  }

  /// Optimized base64 encoding with memory management for XFile (web)
  Future<String> _encodeXFileToBase64Optimized(XFile xFile) async {
    try {
      final fileSize = await xFile.length();

      // For smaller files, use standard approach
      if (fileSize < 1024 * 1024) {
        // 1MB
        final bytes = await xFile.readAsBytes();
        final result = base64Encode(bytes);
        // Clear bytes from memory
        bytes.fillRange(0, bytes.length, 0);
        return result;
      } else {
        // For larger files, use chunked encoding
        return await _encodeXFileToBase64InChunks(xFile);
      }
    } catch (e) {
      _log('Error in optimized base64 encoding for XFile: $e');
      // Fallback to standard encoding
      return base64Encode(await xFile.readAsBytes());
    }
  }

  /// Encode file to base64 in chunks to reduce memory pressure
  Future<String> _encodeToBase64InChunks(File file) async {
    const int chunkSize = 256 * 1024; // 256KB chunks
    final fileSize = await file.length();
    final chunks = <String>[];

    final randomAccessFile = await file.open();
    try {
      int position = 0;
      while (position < fileSize) {
        final remainingBytes = fileSize - position;
        final currentChunkSize =
            remainingBytes < chunkSize ? remainingBytes : chunkSize;

        final chunkBytes = await randomAccessFile.read(currentChunkSize);
        final chunkBase64 = base64Encode(chunkBytes);
        chunks.add(chunkBase64);

        // Clear chunk bytes from memory
        chunkBytes.fillRange(0, chunkBytes.length, 0);

        position += currentChunkSize;
      }

      return chunks.join('');
    } finally {
      await randomAccessFile.close();
    }
  }

  /// Encode XFile to base64 in chunks to reduce memory pressure (for web)
  Future<String> _encodeXFileToBase64InChunks(XFile xFile) async {
    const int chunkSize = 256 * 1024; // 256KB chunks
    final fileSize = await xFile.length();
    final chunks = <String>[];

    // For XFile, we need to read all bytes first since we can't use RandomAccessFile
    // But we'll process in chunks to reduce memory pressure
    final allBytes = await xFile.readAsBytes();
    try {
      int position = 0;
      while (position < fileSize) {
        final remainingBytes = fileSize - position;
        final currentChunkSize =
            remainingBytes < chunkSize ? remainingBytes : chunkSize;

        final chunkBytes =
            allBytes.sublist(position, position + currentChunkSize);
        final chunkBase64 = base64Encode(chunkBytes);
        chunks.add(chunkBase64);

        position += currentChunkSize;
      }

      return chunks.join('');
    } finally {
      // Clear all bytes from memory
      allBytes.fillRange(0, allBytes.length, 0);
    }
  }

  /// Force garbage collection with minimal overhead
  void _forceGarbageCollection() {
    // Only force GC on non-web platforms where it's more effective
    if (!kIsWeb) {
      try {
        // Use a small delay to allow the current operation to complete
        Future.delayed(const Duration(milliseconds: 10), () {
          // Force garbage collection to free memory
          // Note: This is a hint to the Dart VM and may not always run immediately
        });
      } catch (e) {
        // Ignore errors in GC forcing
      }
    }
  }

  /// Get OCR fallback metrics for debugging and analytics
  OcrFallbackMetrics getOcrFallbackMetrics() {
    return _fallbackHandler.getMetrics();
  }

  /// Reset OCR fallback metrics (useful for testing or new sessions)
  void resetOcrFallbackMetrics() {
    _fallbackHandler.resetMetrics();
  }

  /// Get performance monitoring statistics
  OcrPerformanceStats getPerformanceStats() {
    return _monitor.getStats();
  }

  /// Reset performance monitoring statistics
  void resetPerformanceStats() {
    _monitor.resetMetrics();
  }

  /// Get performance history instance
  OcrPerformanceHistory getPerformanceHistory() {
    return _history;
  }

  /// Get performance history summary
  OcrPerformanceSummary getPerformanceHistorySummary() {
    return _history.getPerformanceSummary();
  }

  /// Get adaptive configuration
  OcrAdaptiveConfig getAdaptiveConfig() {
    return _history.config;
  }

  /// Update adaptive configuration
  Future<void> updateAdaptiveConfig(OcrAdaptiveConfig config) async {
    await _history.updateConfig(config);
    _log('Adaptive OCR configuration updated');
  }

  /// Reset performance history
  Future<void> resetPerformanceHistory() async {
    await _history.resetHistory();
    _log('Performance history reset');
  }

  /// Check if cloud mode is currently forced
  bool isCloudModeForced() {
    return _history.shouldForceCloudMode;
  }

  /// Manually force or unforce cloud mode
  Future<void> setForceCloudMode(bool force) async {
    await _history.setForceCloudMode(force);
    _log('Cloud mode force set to: $force');
  }

  /// Get slow operation count
  int getSlowOperationCount() {
    return _history.getSlowOperationCount();
  }

  /// Log memory usage with minimal overhead
  void _logMemoryUsage(String context) {
    if (!kIsWeb) {
      try {
        // Only log memory usage in debug mode to avoid overhead in production
        _log('Memory usage: $context');
      } catch (e) {
        // Ignore memory monitoring errors
      }
    }
  }
}
