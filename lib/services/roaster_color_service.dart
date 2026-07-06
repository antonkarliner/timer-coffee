import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/roaster_logo_cache_manager.dart';

// ---------------------------------------------------------------------------
// Result types
// ---------------------------------------------------------------------------

/// The result of analysing a roaster logo for its dominant color.
sealed class RoasterColorResult {
  const RoasterColorResult();
}

/// No logo URL was available, the image is an SVG, or it could not be fetched.
class RoasterColorNone extends RoasterColorResult {
  const RoasterColorNone();
}

/// The logo was successfully analysed but contains no dominant non-gray color
/// (e.g. a black/white logotype).
class RoasterColorMonochrome extends RoasterColorResult {
  const RoasterColorMonochrome();
}

/// The logo has a clearly dominant non-gray color.
class RoasterColorVibrant extends RoasterColorResult {
  const RoasterColorVibrant(this.color);
  final Color color;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Extracts and caches the dominant color from roaster logo images.
class RoasterColorService {
  static final instance = RoasterColorService._();
  RoasterColorService._();

  // Increment when the extraction algorithm changes to force re-analysis.
  static const _cacheVersion = 'v6';
  static const _cacheVersionKey = 'roaster_color_cache_version';

  // SharedPreferences sentinel values
  static const _sentinelNone = -1;
  static const _sentinelMonochrome = -2;

  final Map<String, RoasterColorResult> _memoryCache = {};
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sharedPrefs async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      // Clear stale cache if algorithm version changed
      final storedVersion = _prefs!.getString(_cacheVersionKey);
      if (storedVersion != _cacheVersion) {
        final keys = _prefs!
            .getKeys()
            .where((k) => k.startsWith('dominant_color_'))
            .toList();
        for (final k in keys) {
          await _prefs!.remove(k);
        }
        await _prefs!.setString(_cacheVersionKey, _cacheVersion);
        _memoryCache.clear();
      }
    }
    return _prefs!;
  }

  /// Analyses a roaster logo and returns a [RoasterColorResult].
  Future<RoasterColorResult> analyseLogoColor(
    String? originalUrl,
    String? mirrorUrl,
  ) async {
    final url = originalUrl ?? mirrorUrl;
    if (url == null) return const RoasterColorNone();

    // SVGs can't be decoded by the image package
    if (url.toLowerCase().endsWith('.svg')) return const RoasterColorNone();

    final cacheKey = _normalizeUrl(url);

    // 1. In-memory cache
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    // 2. SharedPreferences cache
    final prefs = await _sharedPrefs;
    final cachedInt = prefs.getInt('dominant_color_$cacheKey');
    if (cachedInt != null) {
      final result = _resultFromCachedInt(cachedInt);
      _memoryCache[cacheKey] = result;
      return result;
    }

    // 3. Extract from image bytes
    return _fetchAndExtract(url, originalUrl, mirrorUrl, cacheKey, prefs);
  }

  Future<RoasterColorResult> _fetchAndExtract(
    String url,
    String? originalUrl,
    String? mirrorUrl,
    String cacheKey,
    SharedPreferences prefs,
  ) async {
    try {
      final file = await RoasterLogoCacheManager.instance.getSingleFile(
        url,
        key: cacheKey,
      );
      final bytes = await file.readAsBytes();
      final result = await compute(_extractDominantColor, bytes);
      await _storeResult(cacheKey, result, prefs);
      return result;
    } catch (_) {
      // If original fails, try mirror URL
      if (mirrorUrl != null && url == originalUrl) {
        final mirrorKey = _normalizeUrl(mirrorUrl);
        if (!mirrorUrl.toLowerCase().endsWith('.svg')) {
          try {
            final file = await RoasterLogoCacheManager.instance.getSingleFile(
              mirrorUrl,
              key: mirrorKey,
            );
            final bytes = await file.readAsBytes();
            final result = await compute(_extractDominantColor, bytes);
            await _storeResult(cacheKey, result, prefs);
            return result;
          } catch (_) {
            // Fall through
          }
        }
      }
      const result = RoasterColorNone();
      await _storeResult(cacheKey, result, prefs);
      return result;
    }
  }

  Future<void> _storeResult(
    String cacheKey,
    RoasterColorResult result,
    SharedPreferences prefs,
  ) async {
    _memoryCache[cacheKey] = result;
    final value = switch (result) {
      RoasterColorNone() => _sentinelNone,
      RoasterColorMonochrome() => _sentinelMonochrome,
      RoasterColorVibrant(color: final c) => c.toARGB32(),
    };
    await prefs.setInt('dominant_color_$cacheKey', value);
  }

  RoasterColorResult _resultFromCachedInt(int value) {
    if (value == _sentinelNone) return const RoasterColorNone();
    if (value == _sentinelMonochrome) return const RoasterColorMonochrome();
    return RoasterColorVibrant(
      Color.fromARGB(
        (value >> 24) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 8) & 0xFF,
        value & 0xFF,
      ),
    );
  }

  /// Parses a backend-stored hex string into a [RoasterColorResult].
  ///
  /// Accepts:
  /// - `null` / empty → [RoasterColorNone] (not yet computed)
  /// - `'monochrome'` → [RoasterColorMonochrome]
  /// - `'#RRGGBB'` or `'RRGGBB'` → [RoasterColorVibrant] if the color is
  ///   sufficiently bright; [RoasterColorMonochrome] otherwise.
  static RoasterColorResult fromBackendHex(String? hex) {
    if (hex == null || hex.trim().isEmpty) return const RoasterColorNone();
    final trimmed = hex.trim().toLowerCase();
    if (trimmed == 'monochrome') return const RoasterColorMonochrome();
    final clean = trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
    if (clean.length != 6) return const RoasterColorNone();
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return const RoasterColorNone();

    final r = (value >> 16) & 0xFF;
    final g = (value >> 8) & 0xFF;
    final b = value & 0xFF;
    final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);

    // Near-black (maxC < 60, i.e. up to 0x33 per channel): the logo is a
    // dark/black graphic → Monochrome so the screen gets the inverted-neutral
    // treatment (dark bg in light mode, light bg in dark mode).
    // All other colors — including muted creams and low-saturation warm tones
    // like #DDDDCC — pass through as Vibrant: a 30 % blend still produces a
    // perceptible warm tint that matches the brand better than no change.
    if (maxC < 60) return const RoasterColorMonochrome();

    return RoasterColorVibrant(Color(0xFF000000 | value));
  }

  String _normalizeUrl(String url) {
    final uri = Uri.parse(url);
    return uri.replace(query: '', fragment: '').toString();
  }
}

// ---------------------------------------------------------------------------
// Isolate worker
// ---------------------------------------------------------------------------

/// Top-level function for [compute]. Extracts the dominant color from image
/// bytes using saturation-squared weighted hue bucketing.
///
/// Weighing by saturation² means a highly saturated brand pixel (sat=0.8)
/// contributes 44× more than a barely-colored JPEG noise pixel (sat=0.12),
/// so compression artefacts around dark/white backgrounds cannot drown out
/// small but vibrant logo details.
RoasterColorResult _extractDominantColor(Uint8List bytes) {
  try {
    final image = img.decodeImage(bytes);
    if (image == null) return const RoasterColorMonochrome();

    // Keep 100px wide — small enough to be fast, large enough to preserve
    // fine logo details like colored dots or thin lines.
    final small = img.copyResize(image, width: 100);
    final w = small.width;
    final h = small.height;

    // 36 hue buckets × 10° covers the full wheel.
    const hueBuckets = 36;
    // Weight = sum of saturation² × 10000 (integer math, no precision loss)
    final bucketWeight = List.filled(hueBuckets, 0);
    final bucketR = List.filled(hueBuckets, 0.0);
    final bucketG = List.filled(hueBuckets, 0.0);
    final bucketB = List.filled(hueBuckets, 0.0);
    final bucketWeightForAvg = List.filled(hueBuckets, 0.0);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = small.getPixel(x, y);
        if (pixel.a < 128) continue;

        final r = pixel.r.toInt().clamp(0, 255);
        final g = pixel.g.toInt().clamp(0, 255);
        final b = pixel.b.toInt().clamp(0, 255);

        // HSV saturation and value — skips white, black, gray, and dark pixels.
        final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
        final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
        final delta = maxC - minC;

        // Skip near-black pixels (HSV Value < ~20%).
        // JPEG compression around dark logo outlines produces near-black pixels
        // with just enough relative saturation (delta/maxC ≈ 0.20) to pass the
        // saturation filter, but they are not brand colors.
        if (maxC < 50) continue;

        final saturation = maxC == 0 ? 0.0 : delta / maxC;

        // 0.12 threshold: the brightness filter (maxC < 50) already blocks
        // near-black JPEG artifacts, so we can allow muted brand colors like
        // sage green (sat ≈ 0.14–0.16). Near-white noise (maxC ≈ 240, delta ≈ 5)
        // has sat ≈ 0.02 and is blocked here.
        if (saturation < 0.12) continue;

        // Compute hue (0–359°)
        double hue;
        if (maxC == r) {
          hue = ((g - b) / delta) % 6;
        } else if (maxC == g) {
          hue = (b - r) / delta + 2;
        } else {
          hue = (r - g) / delta + 4;
        }
        hue *= 60;
        if (hue < 0) hue += 360;

        final idx = (hue ~/ 10).clamp(0, hueBuckets - 1);

        // Weight = saturation² × 10000 → integer
        final w2 = (saturation * saturation * 10000).round();
        bucketWeight[idx] += w2;
        bucketWeightForAvg[idx] += saturation;
        bucketR[idx] += r * saturation;
        bucketG[idx] += g * saturation;
        bucketB[idx] += b * saturation;
      }
    }

    // Find the hue bucket with the highest saturation² weight
    int maxWeight = 0;
    int maxIdx = -1;
    for (int i = 0; i < hueBuckets; i++) {
      if (bucketWeight[i] > maxWeight) {
        maxWeight = bucketWeight[i];
        maxIdx = i;
      }
    }

    // Require a minimum total weight (equivalent to ~3 fully-saturated pixels
    // at 100px width) to avoid noise winning on nearly-monochrome images.
    if (maxIdx == -1 || maxWeight < 300) return const RoasterColorMonochrome();

    final totalW = bucketWeightForAvg[maxIdx];
    final avgR = (bucketR[maxIdx] / totalW).round().clamp(0, 255);
    final avgG = (bucketG[maxIdx] / totalW).round().clamp(0, 255);
    final avgB = (bucketB[maxIdx] / totalW).round().clamp(0, 255);

    return RoasterColorVibrant(Color.fromARGB(255, avgR, avgG, avgB));
  } catch (_) {
    return const RoasterColorMonochrome();
  }
}
