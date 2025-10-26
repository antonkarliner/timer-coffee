import 'dart:convert';
import 'dart:io';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/services/ocr/ocr_service.dart';
import 'package:coffee_timer/services/ocr/native_ocr_service.dart';

import 'package:coffee_timer/utils/images/image_resizer.dart';
import 'package:coffee_timer/services/clients/beans_label_parser_client.dart';

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

  // OCR gating state (per start() session)
  bool _ocrDisabledForSession = false;
  bool _ocrWarmed = false;
  int _consecutiveOcrTimeouts = 0;

  // Thresholds (ms)
  static const int _coldThresholdMs = 500; // Increased from 300
  static const int _warmThresholdMs = 400; // Increased from 220
  static const int _maxOcrTimeouts = 2; // Allow 2 consecutive timeouts

  // Centralized console logging for this controller
  // Prefix helps filter in aggregated logs
  // Example: [NewBeansOCR] message
  void _log(String msg) {
    AppLogger.debug('[NewBeansOCR] $msg');
  }

  NewBeansImageController({
    required SupabaseClient supabaseClient,
  }) : _client = BeansLabelParserClient(supabaseClient);

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

  // Best-effort static capability gate without extra plugins:
  // - Skip OCR on Web
  // - Allow on iOS/Android; runtime timing guard will disable if too slow
  bool _passesStaticOcrGate() {
    if (kIsWeb) return false;
    // Best-effort: allow on iOS/Android; timing guard will disable if slow.
    try {
      final platform = defaultTargetPlatform;
      return platform == TargetPlatform.iOS ||
          platform == TargetPlatform.android;
    } catch (_) {
      return false;
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

      // Resize and base64 encode
      final List<String> base64Images = [];
      final List<String> ocrSnippets = [];

      // Initialize gating state per session
      // For first-time usage, always disable OCR to ensure better UX
      _ocrDisabledForSession = isFirstTime ? true : !_passesStaticOcrGate();
      _consecutiveOcrTimeouts = 0; // Reset on new session

      if (_ocrDisabledForSession) {
        if (isFirstTime) {
          _log(
              'OCR disabled for first-time usage; sending images only for better UX.');
        } else {
          _log(
              'OCR disabled by static capability gate; will skip on-device OCR.');
        }
      }

      final prepSw = _StopwatchX();
      for (int idx = 0; idx < images.length; idx++) {
        final x = images[idx];

        // Perform OCR on the original image file when accessible and not disabled
        if (!kIsWeb) {
          final file = File(x.path);

          if (!_ocrDisabledForSession) {
            final swOcr = _StopwatchX();
            final text = await _ocrService.recognizeText(file);
            final ocrMs = swOcr.stopMs();

            // Determine threshold depending on warm/cold state
            final thr = _ocrWarmed ? _warmThresholdMs : _coldThresholdMs;
            final over = ocrMs >= thr;

            _log(
                'OCR timing: ${ocrMs}ms (thr=${thr}ms, warmed=${_ocrWarmed}). chars=${text.length} for ${file.path.split('/').last}');

            if (over) {
              _consecutiveOcrTimeouts++;
              _log(
                  'OCR runtime budget exceeded (${ocrMs}ms >= ${thr}ms). Consecutive timeouts: $_consecutiveOcrTimeouts.');
              if (_consecutiveOcrTimeouts >= _maxOcrTimeouts) {
                _ocrDisabledForSession = true;
                _log(
                    'Max consecutive OCR timeouts reached ($_maxOcrTimeouts); disabling OCR for this session.');
              }
            } else {
              _consecutiveOcrTimeouts = 0; // Reset on success
              if (text.isNotEmpty) {
                ocrSnippets.add(text);
              }
              // Mark warmed after first successful pass under threshold
              _ocrWarmed = true;
            }
          }

          // Downscale before sending to reduce bandwidth while keeping label legibility.
          final swResize = _StopwatchX();
          final resized = await ImageResizer.resizeToMax1024(file);
          final resizeMs = swResize.stopMs();
          base64Images.add(base64Encode(await resized.readAsBytes()));
          _log(
              'Resize+encode done in ${resizeMs}ms for ${file.path.split('/').last}');
        } else {
          // Web fallback: no OCR (native plugin is not supported on web).
          final swRead = _StopwatchX();
          base64Images.add(base64Encode(await x.readAsBytes()));
          _log('Web read+encode done in ${swRead.stopMs()}ms for ${x.name}');
        }
      }
      _log(
          'Prep complete in ${prepSw.stopMs()}ms. OCR total chars: ${ocrSnippets.fold<int>(0, (a, b) => a + b.length)} (ocr_enabled=${!_ocrDisabledForSession})');

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
      try {
        final meta =
            (parsed is Map<String, dynamic>) ? parsed['meta'] as Map? : null;
        if (meta != null) {
          _log(
              'Server meta: decided_mode=${meta['decided_mode']}, tokens_used=${meta['tokens_used']}, '
              'limit=${meta['token_limit']}, used_this_month=${meta['tokens_used_this_month']}, '
              'model=${meta['model_used']}, edge_total_ms=${meta['execution_time_ms_total']}, '
              'edge_gemini_ms=${meta['execution_time_ms_gemini']}, '
              'ocr_text_chars_sent=${meta['ocr_text_chars']}, images_count_sent=${meta['images_count']}');
        } else {
          _log(
              'No meta in response. Edge call time (client observed) = ${edgeMs}ms');
        }
      } catch (_) {
        _log(
            'Meta parse failed; Edge call time (client observed) = ${edgeMs}ms');
      }

      onLoading(false);
      _log('Total client flow time: ${swTotal.stopMs()}ms');
      onData(parsed);
    } catch (e, st) {
      onLoading(false);
      _log('Error during OCR/parse: $e\n$st');
      onError(e.toString());
    }
  }
}
