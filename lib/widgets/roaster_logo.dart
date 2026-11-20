import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:coffee_timer/config/supabase_endpoint_resolver.dart';
import 'package:coffeico_plus/coffeico_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'roaster_logo_cache_manager.dart';
import '../services/roaster_logo_client.dart';

class RoasterLogo extends StatefulWidget {
  final String? originalUrl;
  final String? mirrorUrl;
  final IconData placeholderIcon;
  final double height;
  final double? width;
  final double borderRadius;
  final BoxFit? forceFit;
  final void Function(bool isHorizontal)? onAspectRatioDetermined;
  final bool debugForceReanalysis;

  const RoasterLogo({
    super.key,
    required this.originalUrl,
    required this.mirrorUrl,
    this.placeholderIcon = Coffeico.bag_with_bean,
    this.height = 40.0,
    this.width,
    this.borderRadius = 8.0,
    this.forceFit,
    this.onAspectRatioDetermined,
    this.debugForceReanalysis = false,
  });

  @override
  State<RoasterLogo> createState() => _RoasterLogoState();

  @visibleForTesting
  static bool looksLikeGifUrl(String url) {
    final sanitizedUrl = sanitizedLogoUrl(url);
    if (sanitizedUrl == null) return false;

    final lowerUrl = sanitizedUrl.toLowerCase();
    try {
      final uri = Uri.parse(sanitizedUrl);

      if (uri.path.toLowerCase().endsWith('.gif')) return true;

      for (final entry in uri.queryParametersAll.entries) {
        final key = entry.key.toLowerCase();
        if ((key == 'format' || key == 'fm') &&
            entry.value.any((value) => value.toLowerCase() == 'gif')) {
          return true;
        }
      }
    } catch (_) {
      final path = lowerUrl.split('?').first;
      if (path.endsWith('.gif')) return true;
    }

    return lowerUrl.contains('format=gif') || lowerUrl.contains('fm=gif');
  }

  @visibleForTesting
  static String? sanitizedLogoUrl(String? url) {
    final trimmed = url?.trim();
    final uri = trimmed == null ? null : Uri.tryParse(trimmed);
    return uri != null && RoasterLogoClient.isHttpUrl(uri) ? trimmed : null;
  }

  @visibleForTesting
  static String? preferredInitialUrl({
    required String? originalUrl,
    required String? mirrorUrl,
  }) {
    final sanitizedOriginalUrl = sanitizedLogoUrl(originalUrl);
    final sanitizedMirrorUrl = sanitizedLogoUrl(mirrorUrl);

    if (sanitizedOriginalUrl != null &&
        sanitizedMirrorUrl != null &&
        looksLikeGifUrl(sanitizedOriginalUrl)) {
      return sanitizedMirrorUrl;
    }
    return sanitizedOriginalUrl;
  }
}

class _RoasterLogoState extends State<RoasterLogo> {
  static SharedPreferences? _prefs;
  static Future<void>? _prefsInitializer;
  static const String _cacheVersionKey = 'aspect_ratio_cache_version';
  static const String _currentCacheVersion =
      'v2'; // Increment to invalidate old cache

  String? _currentUrl;
  bool _triedMirror = false;
  bool _triedOriginalAfterMirror = false;
  bool _terminalFailure = false;
  bool _handlingError = false;
  bool _errorHandlingScheduled = false;
  Color? _bgColor;
  BoxFit? _fit;
  Uint8List? _logoBytes;

  @override
  void initState() {
    super.initState();
    _currentUrl = RoasterLogo.preferredInitialUrl(
      originalUrl: widget.originalUrl,
      mirrorUrl: widget.mirrorUrl,
    );
    _triedMirror = _startsWithMirror;
    _initialize();
  }

  @override
  void didUpdateWidget(covariant RoasterLogo oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.originalUrl == widget.originalUrl &&
        oldWidget.mirrorUrl == widget.mirrorUrl) {
      return;
    }

    _currentUrl = RoasterLogo.preferredInitialUrl(
      originalUrl: widget.originalUrl,
      mirrorUrl: widget.mirrorUrl,
    );
    _triedMirror = _startsWithMirror;
    _triedOriginalAfterMirror = false;
    _terminalFailure = false;
    _handlingError = false;
    _errorHandlingScheduled = false;
    _fit = null;
    _logoBytes = null;
    _bgColor = null;

    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    _prefsInitializer ??= SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
    await _prefsInitializer;

    final startsWithMirror = _startsWithMirror;
    final originalUrl = _originalUrl;
    final mirrorUrl = _mirrorUrl;

    _terminalFailure = false;

    // Check if original is broken
    if (startsWithMirror) {
      _currentUrl = mirrorUrl;
      _triedMirror = true;
      _triedOriginalAfterMirror = false;
    } else if (originalUrl != null &&
        (_prefs?.getBool('broken_${_normalizeUrl(originalUrl)}') ?? false) &&
        mirrorUrl != null) {
      _currentUrl = mirrorUrl;
      _triedMirror = true;
      _triedOriginalAfterMirror = false;
    } else {
      _currentUrl = originalUrl;
      _triedMirror = false;
      _triedOriginalAfterMirror = false;
    }

    if (mounted) {
      _loadLogo();
    }
  }

  bool get _startsWithMirror =>
      _originalUrl != null &&
      _mirrorUrl != null &&
      RoasterLogo.looksLikeGifUrl(_originalUrl!);

  String? get _originalUrl => RoasterLogo.sanitizedLogoUrl(widget.originalUrl);

  String? get _mirrorUrl => RoasterLogo.sanitizedLogoUrl(widget.mirrorUrl);

  Future<void> _loadLogo() async {
    final loadUrl = _currentUrl;
    if (loadUrl == null || _terminalFailure) {
      if (mounted) setState(() {});
      return;
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cacheKey = _normalizeUrl(loadUrl);
    try {
      final bytes = await RoasterLogoCacheManager.loadBytes(
        SupabaseEndpointResolver.localizeStorageUrl(loadUrl),
        key: cacheKey,
      );
      if (!mounted || _currentUrl != loadUrl) return;
      final vector = RoasterLogoClient.isSvg(Uri.parse(loadUrl));
      final reanalyse =
          widget.debugForceReanalysis ||
          _getCacheVersion() != _currentCacheVersion;
      if (reanalyse) {
        await _clearCacheForUrl(cacheKey);
        await _saveCacheVersion(_currentCacheVersion);
      }
      final cachedFit = reanalyse ? null : _getFitFromCache(cacheKey);
      final fit = vector
          ? BoxFit.contain
          : cachedFit ?? await _computeFit(bytes);
      final color = vector
          ? null
          : cachedFit == null
          ? await _analyzeEdgeLuminance(bytes, isDarkMode)
          : _getBgColorFromCache(cacheKey);
      final horizontal = vector
          ? null
          : cachedFit == null
          ? await _computeIsHorizontal(bytes)
          : _getIsHorizontalFromCache(cacheKey);
      if (!vector && cachedFit == null) {
        await _saveFitToCache(cacheKey, fit);
        await _saveBgColorToCache(cacheKey, color);
        if (horizontal != null) {
          await _saveIsHorizontalToCache(cacheKey, horizontal);
        }
      }
      if (!mounted || _currentUrl != loadUrl) return;
      setState(() {
        _logoBytes = bytes;
        _fit = fit;
        _bgColor = color;
      });
      if (horizontal != null) {
        widget.onAspectRatioDetermined?.call(horizontal);
      }
    } catch (_) {
      await _handleError(failedUrl: loadUrl);
    }
  }

  Future<void> _handleError({String? failedUrl}) async {
    if (_handlingError || !mounted) return;

    final currentUrl = _currentUrl;
    if (currentUrl == null ||
        _terminalFailure ||
        (failedUrl != null && failedUrl != currentUrl)) {
      return;
    }

    _handlingError = true;
    try {
      final originalUrl = _originalUrl;
      final mirrorUrl = _mirrorUrl;

      if (_startsWithMirror &&
          currentUrl == mirrorUrl &&
          originalUrl != null &&
          !_triedOriginalAfterMirror) {
        if (mounted) {
          setState(() {
            _currentUrl = originalUrl;
            _triedOriginalAfterMirror = true;
            _terminalFailure = false;
            _fit = null;
            _logoBytes = null;
            _bgColor = null;
          });
          unawaited(_loadLogo());
        }
        return;
      }

      if (!_triedMirror && mirrorUrl != null) {
        // Mark the originalUrl as broken in prefs
        if (originalUrl != null) {
          await _prefs?.setBool('broken_${_normalizeUrl(originalUrl)}', true);
        }
        if (mounted) {
          setState(() {
            _triedMirror = true;
            _currentUrl = mirrorUrl;
            _terminalFailure = false;
            _fit = null;
            _logoBytes = null;
            _bgColor = null;
          });
          unawaited(_loadLogo());
        }
      } else {
        if (mounted) {
          setState(() {
            _currentUrl = null;
            _terminalFailure = true;
            _fit = null;
            _logoBytes = null;
            _bgColor = null;
          });
        }
      }
    } finally {
      _handlingError = false;
    }
  }

  void _scheduleHandleError(String failedUrl) {
    if (_errorHandlingScheduled) return;

    _errorHandlingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _errorHandlingScheduled = false;
      unawaited(_handleError(failedUrl: failedUrl));
    });
  }

  BoxFit? _getFitFromCache(String cacheKey) {
    final fitString = _prefs?.getString('fit_$cacheKey');
    if (fitString == null) return null;
    return BoxFit.values.firstWhere((e) => e.toString() == fitString);
  }

  Future<void> _saveFitToCache(String cacheKey, BoxFit fit) async {
    await _prefs?.setString('fit_$cacheKey', fit.toString());
  }

  Color? _getBgColorFromCache(String cacheKey) {
    final colorInt = _prefs?.getInt('bg_$cacheKey');
    if (colorInt == null) return null;
    if (colorInt == -1) return null;
    return Color(colorInt);
  }

  Future<void> _saveBgColorToCache(String cacheKey, Color? color) async {
    await _prefs?.setInt('bg_$cacheKey', color?.toARGB32() ?? -1);
  }

  bool? _getIsHorizontalFromCache(String cacheKey) {
    return _prefs?.getBool('horizontal_$cacheKey');
  }

  Future<void> _saveIsHorizontalToCache(
    String cacheKey,
    bool isHorizontal,
  ) async {
    await _prefs?.setBool('horizontal_$cacheKey', isHorizontal);
  }

  String _normalizeUrl(String url) {
    final uri = Uri.parse(url);
    return uri.replace(query: '', fragment: '').toString();
  }

  String? _getCacheVersion() {
    return _prefs?.getString(_cacheVersionKey);
  }

  Future<void> _saveCacheVersion(String version) async {
    await _prefs?.setString(_cacheVersionKey, version);
  }

  Future<void> _clearCacheForUrl(String cacheKey) async {
    await _prefs?.remove('fit_$cacheKey');
    await _prefs?.remove('bg_$cacheKey');
    await _prefs?.remove('horizontal_$cacheKey');
    log('🗑️ Cleared cache for $cacheKey');
  }

  @override
  Widget build(BuildContext context) {
    return _buildLogo(context);
  }

  Widget _buildLogo(BuildContext context) {
    return FutureBuilder(
      future: _prefsInitializer,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            height: widget.height,
            width: widget.width ?? widget.height,
            child: Center(
              child: Icon(widget.placeholderIcon, size: widget.height),
            ),
          );
        }

        if (_currentUrl == null || _terminalFailure) {
          return Icon(widget.placeholderIcon, size: widget.height);
        }

        final bytes = _logoBytes;
        final url = _currentUrl!;
        if (_fit == null || bytes == null) {
          // Still loading
          return SizedBox(
            height: widget.height,
            width: widget.width ?? widget.height,
            child: Center(
              child: Icon(widget.placeholderIcon, size: widget.height),
            ),
          );
        }

        final isSvg = RoasterLogoClient.isSvg(Uri.parse(url));
        final usedFit = widget.forceFit ?? _fit ?? BoxFit.contain;

        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            height: widget.height,
            width: widget.width ?? widget.height,
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: FittedBox(
              fit: usedFit,
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: isSvg
                    ? SvgPicture.memory(
                        bytes,
                        fit: BoxFit.contain,
                        width: widget.width ?? widget.height,
                        height: widget.height,
                        placeholderBuilder: (context) =>
                            Icon(widget.placeholderIcon, size: widget.height),
                        errorBuilder: (context, error, _) {
                          _scheduleHandleError(url);
                          return Icon(
                            widget.placeholderIcon,
                            size: widget.height,
                          );
                        },
                      )
                    : Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, _) {
                          _scheduleHandleError(url);
                          return Icon(
                            widget.placeholderIcon,
                            size: widget.height,
                          );
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Static Analysis Functions (moved from original for clarity) ---
  static Future<BoxFit> _computeFit(Uint8List bytes) async {
    return await compute((Uint8List bytes) {
      try {
        final img.Image? image = img.decodeImage(bytes);
        if (image == null) return BoxFit.contain;

        // Check for transparency
        bool hasTransparency = false;
        for (int y = 0; y < image.height && !hasTransparency; y++) {
          for (int x = 0; x < image.width; x++) {
            if (image.getPixel(x, y).a < 200) {
              hasTransparency = true;
              break;
            }
          }
        }

        if (hasTransparency) {
          // Transparency-based cropping heuristic
          int top = 0,
              bottom = image.height - 1,
              left = 0,
              right = image.width - 1;
          bool topFound = false,
              bottomFound = false,
              leftFound = false,
              rightFound = false;

          for (int y = 0; y < image.height; y++) {
            for (int x = 0; x < image.width; x++) {
              if (image.getPixel(x, y).a > 0) {
                top = y;
                topFound = true;
                break;
              }
            }
            if (topFound) break;
          }

          for (int y = image.height - 1; y >= 0; y--) {
            for (int x = 0; x < image.width; x++) {
              if (image.getPixel(x, y).a > 0) {
                bottom = y;
                bottomFound = true;
                break;
              }
            }
            if (bottomFound) break;
          }

          for (int x = 0; x < image.width; x++) {
            for (int y = 0; y < image.height; y++) {
              if (image.getPixel(x, y).a > 0) {
                left = x;
                leftFound = true;
                break;
              }
            }
            if (leftFound) break;
          }

          for (int x = image.width - 1; x >= 0; x--) {
            for (int y = 0; y < image.height; y++) {
              if (image.getPixel(x, y).a > 0) {
                right = x;
                rightFound = true;
                break;
              }
            }
            if (rightFound) break;
          }

          final w = right - left;
          final h = bottom - top;
          final isSquare = ((w - h).abs() / (w > h ? w : h)) <= 0.15;
          return isSquare ? BoxFit.cover : BoxFit.contain;
        } else {
          // Opaque image: detect solid margins
          List<img.Pixel> corners = [
            image.getPixel(0, 0),
            image.getPixel(image.width - 1, 0),
            image.getPixel(0, image.height - 1),
            image.getPixel(image.width - 1, image.height - 1),
          ];
          int avgR = 0, avgG = 0, avgB = 0;
          for (var p in corners) {
            avgR += p.r.toInt();
            avgG += p.g.toInt();
            avgB += p.b.toInt();
          }
          avgR = (avgR ~/ 4);
          avgG = (avgG ~/ 4);
          avgB = (avgB ~/ 4);

          bool isBg(img.Pixel p) {
            const int delta = 30;
            return (p.r - avgR).abs() <= delta &&
                (p.g - avgG).abs() <= delta &&
                (p.b - avgB).abs() <= delta;
          }

          final int threshW = (image.width * 0.10).floor();
          final int threshH = (image.height * 0.10).floor();

          int top = 0;
          for (; top < image.height; top++) {
            int diffCount = 0;
            for (int x = 0; x < image.width; x++) {
              if (!isBg(image.getPixel(x, top))) diffCount++;
            }
            if (diffCount > threshW) break;
          }
          int bottom = image.height - 1;
          for (; bottom >= 0; bottom--) {
            int diffCount = 0;
            for (int x = 0; x < image.width; x++) {
              if (!isBg(image.getPixel(x, bottom))) diffCount++;
            }
            if (diffCount > threshW) break;
          }
          int left = 0;
          for (; left < image.width; left++) {
            int diffCount = 0;
            for (int y = 0; y < image.height; y++) {
              if (!isBg(image.getPixel(left, y))) diffCount++;
            }
            if (diffCount > threshH) break;
          }
          int right = image.width - 1;
          for (; right >= 0; right--) {
            int diffCount = 0;
            for (int y = 0; y < image.height; y++) {
              if (!isBg(image.getPixel(right, y))) diffCount++;
            }
            if (diffCount > threshH) break;
          }

          final w = right - left;
          final h = bottom - top;
          final double horizMargin = (image.width - w) / image.width;
          final double vertMargin = (image.height - h) / image.height;
          if (horizMargin >= 0.15 || vertMargin >= 0.15) {
            return BoxFit.cover;
          }
          final isSquare = ((w - h).abs() / (w > h ? w : h)) <= 0.15;
          return isSquare ? BoxFit.cover : BoxFit.contain;
        }
      } catch (_) {
        return BoxFit.contain;
      }
    }, bytes);
  }

  static Future<Color?> _analyzeEdgeLuminance(
    Uint8List bytes,
    bool isDarkMode,
  ) async {
    return await compute((List<dynamic> args) {
      final Uint8List bytes = args[0];
      final bool isDarkMode = args[1];
      try {
        final img.Image? image = img.decodeImage(bytes);
        if (image == null) return null;
        final int w = image.width;
        final int h = image.height;
        List<img.Pixel> edgePixels = [];

        bool isTransparent(img.Pixel p) => p.a < 50;

        for (int x = 0; x < w; x++) {
          for (int y in [0, h - 1]) {
            final p = image.getPixel(x, y);
            if (p.a > 200) {
              bool touchesTransparency = false;
              for (var dy in [-1, 0, 1]) {
                int ny = y + dy;
                if (ny < 0 || ny >= h) continue;
                if (isTransparent(image.getPixel(x, ny))) {
                  touchesTransparency = true;
                }
              }
              if (touchesTransparency) edgePixels.add(p);
            }
          }
        }
        for (int y = 1; y < h - 1; y++) {
          for (int x in [0, w - 1]) {
            final p = image.getPixel(x, y);
            if (p.a > 200) {
              bool touchesTransparency = false;
              for (var dx in [-1, 0, 1]) {
                int nx = x + dx;
                if (nx < 0 || nx >= w) continue;
                if (isTransparent(image.getPixel(nx, y))) {
                  touchesTransparency = true;
                }
              }
              if (touchesTransparency) edgePixels.add(p);
            }
          }
        }
        if (edgePixels.isEmpty) return null;

        double luminanceSum = 0;
        for (var p in edgePixels) {
          int r = p.r.toInt();
          int g = p.g.toInt();
          int b = p.b.toInt();
          double l =
              0.2126 * (r / 255) + 0.7152 * (g / 255) + 0.0722 * (b / 255);
          luminanceSum += l;
        }
        double avgLuminance = luminanceSum / edgePixels.length;

        if (avgLuminance >= 0.85) {
          if (!isDarkMode) {
            return Colors.black.withValues(alpha: 0.15);
          }
        } else if (avgLuminance <= 0.25) {
          if (isDarkMode) {
            return Colors.white;
          }
        }
        return null;
      } catch (_) {
        return null;
      }
    }, [bytes, isDarkMode]);
  }

  static Future<bool> _computeIsHorizontal(Uint8List bytes) async {
    return await compute((Uint8List bytes) {
      try {
        final img.Image? image = img.decodeImage(bytes);
        if (image == null) return false;

        // Consider horizontal if width is significantly greater than height (20% or more)
        final aspectRatio = image.width / image.height;
        final isHorizontal = aspectRatio > 1.2;
        log(
          '🔍 Image analysis: ${image.width}x${image.height}, aspectRatio: $aspectRatio, isHorizontal: $isHorizontal',
        );
        return isHorizontal;
      } catch (_) {
        return false;
      }
    }, bytes);
  }
}
