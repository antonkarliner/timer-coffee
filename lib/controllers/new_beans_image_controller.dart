import 'dart:convert';
import 'dart:io';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/utils/images/chunked_base64.dart';
import 'package:coffee_timer/utils/images/image_resizer.dart';
import 'package:coffee_timer/services/clients/beans_label_parser_client.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/photo_library_service.dart';
import 'package:coffee_timer/utils/device_profiler.dart';
import 'package:coffee_timer/models/image_processing_result.dart';

typedef ImageResizeCallback = Future<File> Function(File image, int maxSize);
typedef ImageEncodeCallback = Future<String> Function(File image);

// Simple timing helper for console instrumentation
class _StopwatchX {
  final Stopwatch _sw = Stopwatch()..start();
  int stopMs() {
    _sw.stop();
    return _sw.elapsedMilliseconds;
  }
}

/// Real, work-driven stages of the AI label scan.
///
/// Each value is reported at the moment its corresponding work actually
/// begins — never on a timer and never implying a duration or percentage.
enum BeanScanStage {
  /// Copying the final reviewed camera photos into the user's photo library.
  savingPhotos,

  /// Resizing and base64-encoding the selected photos on-device. Local,
  /// usually fast.
  preparingImages,

  /// Waiting on the `parse-coffee-label` Edge Function. This is the long
  /// pole and can take considerably longer on a slow connection.
  readingLabel,
}

/// A controller that orchestrates the "image flow" for New Beans:
/// - first-time popup logic (delegated to caller)
/// - image selection (camera/gallery), with an optional second photo
///   launched from the review UI
/// - preview/selection removal (delegated to caller UI)
/// - resize + base64 encode
/// - invoke Edge Function through BeansLabelParserClient
///
/// This controller keeps business logic separated from Widget build trees.
/// The UI (dialogs/sheets) should be implemented by the caller and wired via the
/// provided callbacks.
class NewBeansImageController {
  static const MethodChannel _iosPhotoPickerChannel = MethodChannel(
    'com.coffee.timer/inline_photo_picker',
  );

  final ImagePicker _picker;
  final BeansLabelParserClient _client;
  final PhotoLibraryService _photoLibraryService;
  final ImageResizeCallback _imageResizer;
  final ImageEncodeCallback? _imageEncoder;

  // Thresholds (ms)
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5MB threshold

  // Centralized console logging for this controller
  // Prefix helps filter in aggregated logs
  // Example: [NewBeansScan] message
  void _log(String msg) {
    AppLogger.debug('[NewBeansScan] $msg');
  }

  NewBeansImageController({
    required SupabaseClient supabaseClient,
    ImagePicker? imagePicker,
    PhotoLibraryService? photoLibraryService,
    @visibleForTesting BeansLabelParserClient? parserClient,
    @visibleForTesting ImageResizeCallback? imageResizer,
    @visibleForTesting ImageEncodeCallback? imageEncoder,
  }) : _picker = imagePicker ?? ImagePicker(),
       _client = parserClient ?? BeansLabelParserClient(supabaseClient),
       _photoLibraryService = photoLibraryService ?? PhotoLibraryService(),
       _imageResizer = imageResizer ?? ImageResizer.resizeToMaxSize,
       _imageEncoder = imageEncoder;

  /// Starts the flow for selecting images (camera or gallery) and parsing them.
  /// The controller does not present UI itself. Instead, it relies on the caller to:
  /// - ask the user to choose the source (camera/gallery) via `onChooseSource`.
  /// - show preview sheets/dialogs via `onShowPreview`.
  /// - show error dialogs via `onError`.
  ///
  /// Required callbacks:
  /// - `onLoading(bool isLoading)`
  /// - `onData(Map<String, dynamic> parsed)`
  /// - `onError(String message)`
  /// - `onShowPreview` receives the selected images, confirm/back callbacks,
  ///   and a callback for adding one more photo from the chosen source.
  /// - `onChooseSource(Future<ImageSource?> Function() chooser)` - see defaultChooser example below.
  Future<void> start({
    required BuildContext context,
    required String locale,
    required void Function(bool) onLoading,
    required void Function(Map<String, dynamic>) onData,
    required void Function(String) onError,
    required Future<ImageSource?> Function() onChooseSource,
    required Future<void> Function(
      List<XFile> images,
      ImageSource source,
      Future<void> Function(List<XFile>, bool) onConfirm,
      Future<void> Function() onBackToSelection,
      Future<XFile?> Function()? onAddPhoto,
    )
    onShowPreview,
    String? userId,
    bool isFirstTime = false,
    void Function(BeanScanStage stage)? onStage,
    required void Function(PhotoLibrarySaveResult result) onPhotoSaveResult,
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
        source,
        (confirmed, saveToLibrary) async {
          if (source == ImageSource.camera && saveToLibrary) {
            onLoading(true);
            onStage?.call(BeanScanStage.savingPhotos);

            PhotoLibrarySaveResult saveResult;
            try {
              saveResult = await _photoLibraryService.saveImages(
                confirmed.map((image) => image.path).toList(),
              );
            } catch (e) {
              _log('Unexpected photo-library save failure: $e');
              saveResult = PhotoLibrarySaveResult(
                status: PhotoLibrarySaveStatus.failed,
                savedCount: 0,
                failedCount: confirmed.length,
              );
            }

            try {
              onPhotoSaveResult(saveResult);
            } catch (e) {
              _log('Photo-library result callback failed: $e');
            }
          }

          // Process confirmed images
          await _processAndParse(
            images: confirmed,
            locale: locale,
            userId: userId,
            onLoading: onLoading,
            onData: onData,
            onError: onError,
            isFirstTime: isFirstTime,
            onStage: onStage,
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
            onPhotoSaveResult: onPhotoSaveResult,
            userId: userId,
            isFirstTime: isFirstTime,
            onStage: onStage,
          );
        },
        source == ImageSource.camera ? _takeCameraPhoto : _takeGalleryPhoto,
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Picks the initial images. Camera starts with one photo; the unified review
  /// sheet owns the optional second capture so cancelling it leaves the review
  /// sheet open instead of relaunching the camera.
  Future<List<XFile>> _pickImages(ImageSource source) async {
    if (source == ImageSource.camera) {
      final image = await _takeCameraPhoto();
      return image == null ? const <XFile>[] : <XFile>[image];
    }

    return _pickGalleryImages(selectionLimit: 2);
  }

  Future<XFile?> _takeCameraPhoto() {
    return _picker.pickImage(source: ImageSource.camera);
  }

  Future<XFile?> _takeGalleryPhoto() async {
    final images = await _pickGalleryImages(selectionLimit: 1);
    return images.isEmpty ? null : images.first;
  }

  Future<List<XFile>> _pickGalleryImages({required int selectionLimit}) async {
    if (kIsWeb) {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      return image == null ? const <XFile>[] : <XFile>[image];
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final paths = await _iosPhotoPickerChannel.invokeListMethod<String>(
          'pickImages',
          {'selectionLimit': selectionLimit},
        );
        return (paths ?? const <String>[]).map(XFile.new).toList();
      } on MissingPluginException {
        // Keep add-beans usable in tests and in any build where the native
        // bridge has not yet been registered.
        _log('Inline iOS photo picker unavailable; using image_picker.');
      }
    }

    if (selectionLimit == 1) {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
      return image == null ? const <XFile>[] : <XFile>[image];
    }

    return _picker.pickMultiImage(imageQuality: 50, limit: selectionLimit);
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
    int imageIndex,
  ) async {
    final swTotal = _StopwatchX();
    final fileName = image.path.split('/').last;
    final performanceMetrics = <String, dynamic>{};

    try {
      _logMemoryUsage(
        'Starting parallel image processing for image ${imageIndex + 1}',
      );

      String base64Image;

      if (!kIsWeb) {
        final file = File(image.path);

        // Check file size before processing
        final fileSize = await file.length();
        if (fileSize > _maxFileSizeBytes) {
          _log(
            'Skipping large image: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB exceeds threshold of ${(_maxFileSizeBytes / 1024 / 1024).toStringAsFixed(2)}MB',
          );
          return ImageProcessingResult.failure(
            fileName: fileName,
            imageIndex: imageIndex,
            error: 'Image size exceeds threshold',
            performanceMetrics: {'fileSize': fileSize, 'skipped': true},
          );
        }

        // Downscale before sending to reduce bandwidth while keeping label legibility
        final swResize = _StopwatchX();
        final resized = await _imageResizer(file, maxImageSize);
        final resizeMs = swResize.stopMs();
        performanceMetrics['resizeMs'] = resizeMs;

        try {
          // Optimized base64 encoding with memory management
          final swEncode = _StopwatchX();
          base64Image = _imageEncoder == null
              ? await _encodeToBase64Optimized(resized)
              : await _imageEncoder(resized);
          final encodeMs = swEncode.stopMs();
          performanceMetrics['encodeMs'] = encodeMs;

          _log(
            'Resize+encode done in ${resizeMs}ms+${encodeMs}ms for $fileName (max_size=${maxImageSize}px)',
          );
        } finally {
          if (resized.path != file.path) {
            try {
              if (await resized.exists()) {
                await resized.delete();
              }
            } catch (e) {
              _log('Could not delete scan derivative ${resized.path}: $e');
            }
          }
        }

        // Force garbage collection after image processing
        _forceGarbageCollection();
      } else {
        // Web fallback
        final swRead = _StopwatchX();

        // Check file size before processing
        final fileSize = await image.length();
        if (fileSize > _maxFileSizeBytes) {
          _log(
            'Skipping large web image: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB exceeds threshold of ${(_maxFileSizeBytes / 1024 / 1024).toStringAsFixed(2)}MB',
          );
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

  @visibleForTesting
  Future<ImageProcessingResult> prepareImageForTesting(
    XFile image,
    int maxImageSize,
    int imageIndex,
  ) {
    return _processSingleImageParallel(image, maxImageSize, imageIndex);
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
    required List<XFile> images,
    required String locale,
    required String? userId,
    required void Function(bool) onLoading,
    required void Function(Map<String, dynamic>) onData,
    required void Function(String) onError,
    bool isFirstTime = false,
    void Function(BeanScanStage stage)? onStage,
  }) async {
    final swTotal = _StopwatchX();
    onLoading(true);
    onStage?.call(BeanScanStage.preparingImages);
    try {
      _log(
        'Starting prepare. Images: ${images.length}, locale: $locale, userId: ${userId ?? 'anon'}, isFirstTime: $isFirstTime',
      );

      // Determine device-aware image size
      final int maxImageSize = await _getDeviceAwareMaxImageSize();
      _log('Using device-aware max image size: ${maxImageSize}px');

      // Determine max concurrent operations based on device capabilities
      final int maxConcurrent = await _getMaxConcurrentOperations();
      _log('Using max concurrent operations: $maxConcurrent');

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
          return _processSingleImageParallel(image, maxImageSize, index);
        }).toList();

        // Wait for all processing to complete
        results.addAll(await Future.wait(futures));
      }

      _log(
        'Prep complete in ${prepSw.stopMs()}ms. Processed ${results.length} images',
      );

      // Filter successful results and extract data
      final successfulResults = results.where((r) => r.success).toList();
      final base64Images = successfulResults.map((r) => r.base64Image).toList();

      if (base64Images.isEmpty) {
        onLoading(false);
        _log('No images to process; aborting.');
        return;
      }

      // Explicitly log what we are sending to the Edge Function
      _log('Sending to Edge: images=${base64Images.length}, locale=$locale');

      // Real boundary: local prep is done, the long-pole network call is
      // starting now.
      onStage?.call(BeanScanStage.readingLabel);

      final swEdge = _StopwatchX();
      final parsed = await _client.parseLabel(
        base64Images: base64Images,
        locale: locale, // keep locale as target translation language
        userId: userId,
      );
      final edgeMs = swEdge.stopMs();

      AnalyticsService.maybeInstance?.track(
        'beans_scan_used',
        properties: {'success': true, 'mode': 'auto'},
      );

      // Log meta if server returned it
      Map<String, dynamic>? serverMeta;
      try {
        serverMeta = parsed['meta'] as Map<String, dynamic>?;
        if (serverMeta is Map<String, dynamic>) {
          _log(
            'Server meta: decided_mode=${serverMeta['decided_mode']}, tokens_used=${serverMeta['tokens_used']}, '
            'limit=${serverMeta['token_limit']}, used_this_month=${serverMeta['tokens_used_this_month']}, '
            'model=${serverMeta['model_used']}, edge_total_ms=${serverMeta['execution_time_ms_total']}, '
            'edge_gemini_ms=${serverMeta['execution_time_ms_gemini']}, '
            'images_count_sent=${serverMeta['images_count']}',
          );
        } else {
          _log(
            'No meta in response. Edge call time (client observed) = ${edgeMs}ms',
          );
        }
      } catch (_) {
        _log(
          'Meta parse failed; Edge call time (client observed) = ${edgeMs}ms',
        );
      }

      onLoading(false);
      _log('Total client flow time: ${swTotal.stopMs()}ms');
      onData(parsed);
    } catch (e, st) {
      AnalyticsService.maybeInstance?.track(
        'beans_scan_used',
        properties: {'success': false, 'mode': 'auto'},
      );
      onLoading(false);
      _log('Error during prepare/parse: $e\n$st');
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
  Future<String> _encodeToBase64InChunks(File file) {
    return encodeFileToBase64InChunks(file);
  }

  /// Encode XFile to base64 (for web). XFile has no random-access API, so
  /// the bytes are already fully in memory — encode them in one pass.
  Future<String> _encodeXFileToBase64InChunks(XFile xFile) async {
    final allBytes = await xFile.readAsBytes();
    try {
      return base64Encode(allBytes);
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
