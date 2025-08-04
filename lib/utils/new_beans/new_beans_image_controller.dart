import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coffee_timer/utils/new_beans/image_resizer.dart';
import 'package:coffee_timer/utils/new_beans/beans_label_parser_client.dart';

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
      Future<void> Function(List<XFile> confirmed) onConfirm,
      Future<void> Function() onBackToSelection,
    ) onShowPreview,
    String? userId,
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

  Future<void> _processAndParse({
    required BuildContext context,
    required List<XFile> images,
    required String locale,
    required String? userId,
    required void Function(bool) onLoading,
    required void Function(Map<String, dynamic>) onData,
    required void Function(String) onError,
  }) async {
    onLoading(true);
    try {
      // Resize and base64 encode
      final List<String> base64Images = [];
      for (final x in images) {
        // On web XFile.path can be a blob URL; image resizing here is for mobile/desktop.
        if (!kIsWeb) {
          final resized = await ImageResizer.resizeToMax1024(File(x.path));
          base64Images.add(base64Encode(await resized.readAsBytes()));
        } else {
          // On web we cannot access local files as File; readAsBytes() is not supported for blob URLs here.
          // Fallback: let the edge function handle the original resolution via network path if applicable.
          // If you want full web support, consider reading bytes from XFile directly when available.
          base64Images.add(base64Encode(await x.readAsBytes()));
        }
      }

      if (base64Images.isEmpty) {
        onLoading(false);
        return;
      }

      // Invoke edge function
      final parsed = await _client.parseLabel(
        base64Images: base64Images,
        locale: locale,
        userId: userId,
      );

      onLoading(false);
      onData(parsed);
    } catch (e) {
      onLoading(false);
      // Map well-known messages if needed; UI can translate.
      onError(e.toString());
    }
  }
}
