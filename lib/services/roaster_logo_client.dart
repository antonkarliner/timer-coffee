import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// Bounds the download before buffering and the raster before allocating a frame.
/// Each request owns its transport so rejection cancels that transfer only.
class RoasterLogoClient extends http.BaseClient {
  static const byteLimit = 5 * 1024 * 1024;
  static const pixelLimit = 4 * 1024 * 1024;
  static const maxSide = 512;
  static const _maxSvgBytes = 256 * 1024;
  static const _maxConcurrentDownloads = 4;
  static int _activeDownloads = 0;
  static final _waiting = Queue<Completer<void>>();

  static bool isSvg(Uri uri) => uri.path.toLowerCase().endsWith('.svg');

  static bool isHttpUrl(Uri uri) =>
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty;

  static Future<Uint8List> download(Uri uri) async {
    final response = await RoasterLogoClient().get(uri);
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw const FormatException('Logo download failed');
    }
    return response.bodyBytes;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!isHttpUrl(request.url)) {
      throw const FormatException('Unsupported logo URL');
    }
    if (_activeDownloads < _maxConcurrentDownloads) {
      _activeDownloads++;
    } else {
      final slot = Completer<void>();
      _waiting.addLast(slot);
      await slot.future;
    }
    final transport = http.Client();
    try {
      return await _fetch(
        transport,
        request,
      ).timeout(const Duration(seconds: 8));
    } finally {
      transport.close();
      if (_waiting.isEmpty) {
        _activeDownloads--;
      } else {
        _waiting.removeFirst().complete();
      }
    }
  }

  Future<http.StreamedResponse> _fetch(
    http.Client transport,
    http.BaseRequest request,
  ) async {
    final response = await transport.send(request);
    if (response.statusCode != 200) {
      return http.StreamedResponse(
        const Stream.empty(),
        response.statusCode,
        headers: response.headers,
      );
    }
    final vector = isSvg(request.url);
    final bytes = await readBounded(
      response,
      limit: vector ? _maxSvgBytes : byteLimit,
    );
    final result = vector ? _boundedSvg(bytes) : await normalizedRaster(bytes);
    return http.StreamedResponse(
      Stream.value(result),
      200,
      contentLength: result.length,
      headers: {
        ...response.headers,
        'content-type': vector ? 'image/svg+xml' : 'image/png',
        'content-length': result.length.toString(),
      },
    );
  }

  static Future<Uint8List> readBounded(
    http.StreamedResponse response, {
    int limit = byteLimit,
  }) async {
    if ((response.contentLength ?? 0) > limit) {
      throw const FormatException('Logo exceeds byte limit');
    }
    final data = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      if (chunk.length > limit - data.length) {
        throw const FormatException('Logo exceeds byte limit');
      }
      data.add(chunk);
    }
    return data.takeBytes();
  }

  static Uint8List _boundedSvg(Uint8List bytes) {
    final text = utf8.decode(bytes);
    // SVGs are rendered locally. Reject deferred resources, recursively
    // reusable content, and dense vectors before parsing them as a picture.
    if (RegExp(
          r'<\s*(?:!DOCTYPE|!ENTITY|(?:[\w-]+:)?(?:image|use|filter|pattern|foreignObject|script)\b)',
          caseSensitive: false,
        ).hasMatch(text) ||
        '<'.allMatches(text).length > 3000) {
      throw const FormatException('Unsupported logo SVG');
    }
    return bytes;
  }

  static void _checkDimensions(int width, int height) {
    if (width <= 0 || height <= 0 || width > pixelLimit ~/ height) {
      throw const FormatException('Logo exceeds pixel limit');
    }
  }

  static void _checkPngChunks(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    if (bytes.length < 8 ||
        data.getUint32(0) != 0x89504e47 ||
        data.getUint32(4) != 0x0d0a1a0a) {
      return;
    }
    var offset = 8;
    while (offset + 12 <= bytes.length) {
      final length = data.getUint32(offset);
      final next = offset + 12 + length;
      if (next > bytes.length) throw const FormatException('Truncated PNG');
      final type = data.getUint32(offset + 4);
      if (type == 0x6163544c || // acTL
          type == 0x69434350 || // iCCP
          type == 0x7a545874 || // zTXt
          type == 0x69545874) {
        // iTXt
        throw const FormatException('Unsupported PNG metadata or animation');
      }
      offset = next;
    }
  }

  static Future<Uint8List> normalizedRaster(Uint8List bytes) async {
    _checkPngChunks(bytes);
    if (kIsWeb) {
      // Flutter's encoded ImageDescriptor does not expose dimensions on web.
      // Inspect metadata with the relevant codec before asking it for a frame.
      final data = ByteData.sublistView(bytes);
      final decoder = switch (bytes.length) {
        >= 12 when data.getUint32(0) == 0x89504e47 => img.PngDecoder(),
        >= 4 when data.getUint16(0) == 0xffd8 => img.JpegDecoder(),
        >= 12
            when data.getUint32(0) == 0x52494646 &&
                data.getUint32(8) == 0x57454250 =>
          img.WebPDecoder(),
        _ => throw const FormatException('Unsupported web logo format'),
      };
      final info = decoder.startDecode(bytes);
      if (info == null || decoder.numFrames() > 1) {
        throw const FormatException('Unreadable or animated logo');
      }
      _checkDimensions(info.width, info.height);
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: info.width >= info.height && info.width > maxSide
            ? maxSide
            : null,
        targetHeight: info.height > info.width && info.height > maxSide
            ? maxSide
            : null,
      );
      return _encodeFirstFrame(codec);
    }

    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        final width = descriptor.width;
        final height = descriptor.height;
        _checkDimensions(width, height);
        final codec = await descriptor.instantiateCodec(
          targetWidth: width >= height && width > maxSide ? maxSide : null,
          targetHeight: height > width && height > maxSide ? maxSide : null,
        );
        return await _encodeFirstFrame(codec);
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
  }

  static Future<Uint8List> _encodeFirstFrame(ui.Codec codec) async {
    try {
      if (codec.frameCount != 1) throw const FormatException('Animated logo');
      final frame = await codec.getNextFrame();
      try {
        final png = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (png == null) throw const FormatException('Unreadable logo');
        return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}
