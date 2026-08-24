import 'dart:io';

import 'package:flutter/services.dart';

enum PhotoLibrarySaveStatus { saved, partial, denied, failed, unsupported }

class PhotoLibrarySaveResult {
  const PhotoLibrarySaveResult({
    required this.status,
    required this.savedCount,
    required this.failedCount,
  });

  final PhotoLibrarySaveStatus status;
  final int savedCount;
  final int failedCount;
}

class PhotoLibraryService {
  PhotoLibraryService({
    MethodChannel channel = const MethodChannel(
      'com.coffee.timer/photo_library',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<PhotoLibrarySaveResult> saveImages(List<String> paths) async {
    try {
      return await _saveImages(paths);
    } catch (_) {
      return PhotoLibrarySaveResult(
        status: PhotoLibrarySaveStatus.failed,
        savedCount: 0,
        failedCount: paths.length,
      );
    }
  }

  Future<PhotoLibrarySaveResult> _saveImages(List<String> paths) async {
    if (paths.isEmpty) {
      return const PhotoLibrarySaveResult(
        status: PhotoLibrarySaveStatus.failed,
        savedCount: 0,
        failedCount: 0,
      );
    }

    final validPaths = <String>[];
    var validationFailures = 0;
    for (final path in paths) {
      if (path.trim().isEmpty || !await File(path).exists()) {
        validationFailures++;
      } else {
        validPaths.add(path);
      }
    }

    if (validPaths.isEmpty) {
      return PhotoLibrarySaveResult(
        status: PhotoLibrarySaveStatus.failed,
        savedCount: 0,
        failedCount: validationFailures,
      );
    }

    try {
      final response = await _channel.invokeMethod<Object?>(
        'saveImages',
        <String, Object>{'paths': validPaths},
      );
      return _normalizeResponse(
        response,
        nativePathCount: validPaths.length,
        validationFailures: validationFailures,
      );
    } on MissingPluginException {
      return PhotoLibrarySaveResult(
        status: PhotoLibrarySaveStatus.unsupported,
        savedCount: 0,
        failedCount: paths.length,
      );
    } on PlatformException {
      return PhotoLibrarySaveResult(
        status: PhotoLibrarySaveStatus.failed,
        savedCount: 0,
        failedCount: paths.length,
      );
    }
  }

  PhotoLibrarySaveResult _normalizeResponse(
    Object? response, {
    required int nativePathCount,
    required int validationFailures,
  }) {
    final totalPathCount = nativePathCount + validationFailures;
    if (response is! Map<Object?, Object?>) {
      return _malformedResult(totalPathCount);
    }

    final status = _parseStatus(response['status']);
    final savedCount = response['savedCount'];
    final failedCount = response['failedCount'];
    if (status == null ||
        savedCount is! int ||
        failedCount is! int ||
        savedCount < 0 ||
        failedCount < 0 ||
        savedCount + failedCount != nativePathCount ||
        !_countsMatchStatus(status, savedCount, failedCount)) {
      return _malformedResult(totalPathCount);
    }

    final totalFailedCount = failedCount + validationFailures;
    final normalizedStatus = switch (status) {
      PhotoLibrarySaveStatus.saved when totalFailedCount > 0 =>
        PhotoLibrarySaveStatus.partial,
      _ => status,
    };

    return PhotoLibrarySaveResult(
      status: normalizedStatus,
      savedCount: savedCount,
      failedCount: totalFailedCount,
    );
  }

  PhotoLibrarySaveStatus? _parseStatus(Object? value) {
    return switch (value) {
      'saved' => PhotoLibrarySaveStatus.saved,
      'partial' => PhotoLibrarySaveStatus.partial,
      'denied' => PhotoLibrarySaveStatus.denied,
      'failed' => PhotoLibrarySaveStatus.failed,
      'unsupported' => PhotoLibrarySaveStatus.unsupported,
      _ => null,
    };
  }

  bool _countsMatchStatus(
    PhotoLibrarySaveStatus status,
    int savedCount,
    int failedCount,
  ) {
    return switch (status) {
      PhotoLibrarySaveStatus.saved => savedCount > 0 && failedCount == 0,
      PhotoLibrarySaveStatus.partial => savedCount > 0 && failedCount > 0,
      PhotoLibrarySaveStatus.denied ||
      PhotoLibrarySaveStatus.failed ||
      PhotoLibrarySaveStatus.unsupported => savedCount == 0 && failedCount > 0,
    };
  }

  PhotoLibrarySaveResult _malformedResult(int totalPathCount) {
    return PhotoLibrarySaveResult(
      status: PhotoLibrarySaveStatus.failed,
      savedCount: 0,
      failedCount: totalPathCount,
    );
  }
}
