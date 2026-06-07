import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coffee_timer/config/supabase_endpoint_resolver.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/moments_service.dart';
import 'roaster_logo_cache_manager.dart';

class RoasterLogo extends StatefulWidget {
  final String? originalUrl;
  final String? mirrorUrl;
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
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
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

class _RoasterLogoState extends State<RoasterLogo>
    with SingleTickerProviderStateMixin {
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

  // Steam puff cameo — fires on double-tap, ~600ms.
  late final AnimationController _steamController;
  bool _showSteam = false;

  @override
  void initState() {
    super.initState();
    _steamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _steamController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showSteam = false);
      }
    });
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
    _bgColor = null;

    unawaited(_initialize());
  }

  @override
  void dispose() {
    _steamController.dispose();
    super.dispose();
  }

  /// Double-tap easter egg: a small steam puff drifts up from the top of the
  /// logo. Idempotent: re-tapping while the puff is mid-animation simply
  /// restarts the cycle.
  void _handleDoubleTap() {
    HapticFeedback.selectionClick();
    // Best-effort discovery mark — silently no-op if MomentsService isn't
    // provided (e.g. in widget tests that pump the logo in isolation).
    try {
      context.read<MomentsService>().markDiscovered('steam_puff');
    } catch (_) {
      // No provider in scope; just play the animation.
    }
    setState(() => _showSteam = true);
    _steamController
      ..reset()
      ..forward();
  }

  /// Builds a pair of mirrored steam puffs that drift up-and-outward from the
  /// logo's left and right edges. Sized in logical pixels relative to the
  /// logo height so the cameo scales with the host (a 40px logo gets a 36px
  /// puff; a hero header logo gets a meatier puff).
  ///
  /// Both puffs are rendered as positioned `💨` `Text` glyphs inside the
  /// surrounding `Stack`. The left puff is mirrored via `Transform.scale`
  /// so the motion lines visually trail toward the logo on both sides.
  List<Widget> _buildSteamPuffs() {
    final puffSize = (widget.height * 0.9).clamp(28.0, 64.0);
    return [
      _buildSteamPuff(left: false, puffSize: puffSize),
      _buildSteamPuff(left: true, puffSize: puffSize),
    ];
  }

  Widget _buildSteamPuff({required bool left, required double puffSize}) {
    return AnimatedBuilder(
      animation: _steamController,
      builder: (context, _) {
        final v = _steamController.value;
        // Eased out so the puff shoots out fast and decelerates.
        final eased = Curves.easeOutCubic.transform(v);
        // Horizontal drift: the puff exits the logo bounds and keeps going.
        final dx = (puffSize * 0.55) + eased * (puffSize * 1.4);
        // Slight upward arc, peaks around 70% of the cycle.
        final dy = -math.sin(v * math.pi * 0.7) * (puffSize * 0.35);
        // Grow slightly as it leaves; fade out near the end.
        final scale = 0.55 + eased * 0.55;
        final opacity = (1 - v * v).clamp(0.0, 1.0);

        // Anchor so we sit on the side of the logo at vertical center.
        final logoH = widget.height;
        final logoW = widget.width ?? widget.height;
        final topAnchor = (logoH - puffSize) / 2 + dy;

        return Positioned(
          left: left ? -dx : null,
          right: left ? null : -dx,
          top: topAnchor,
          width: logoW,
          child: Align(
            alignment: left ? Alignment.centerLeft : Alignment.centerRight,
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scaleX: left ? -scale : scale,
                scaleY: scale,
                child: Text('💨', style: TextStyle(fontSize: puffSize)),
              ),
            ),
          ),
        );
      },
    );
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
    final fit = _getFitFromCache(cacheKey);
    final color = _getBgColorFromCache(cacheKey);
    final isHorizontal = _getIsHorizontalFromCache(cacheKey);
    final cacheVersion = _getCacheVersion();

    // Check if we need to force re-analysis (debug mode or cache version mismatch)
    final forceReanalysis =
        widget.debugForceReanalysis || cacheVersion != _currentCacheVersion;

    if (forceReanalysis) {
      log(
        '🔄 Forcing re-analysis for $loadUrl (debug: ${widget.debugForceReanalysis}, cache version: $cacheVersion vs $_currentCacheVersion)',
      );
      // Clear old cache if version mismatch
      if (cacheVersion != _currentCacheVersion) {
        await _clearCacheForUrl(cacheKey);
        await _saveCacheVersion(_currentCacheVersion);
      }
    }

    if (fit != null && !forceReanalysis) {
      log(
        '✅ Using cached metadata for $loadUrl, isHorizontal: ${isHorizontal ?? false}',
      );
      if (mounted) {
        setState(() {
          _fit = fit;
          _bgColor = color;
        });

        // Notify parent widget about the aspect ratio immediately for cached values
        if (isHorizontal != null) {
          log(
            '📢 Notifying parent widget immediately: isHorizontal = $isHorizontal',
          );
          // Use WidgetsBinding to ensure callback happens in the same frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              log(
                '🚀 Executing callback for cached value: isHorizontal = $isHorizontal',
              );
              widget.onAspectRatioDetermined?.call(isHorizontal);
            }
          });
        }
      }
      return;
    }

    log(
      'ℹ️ No cached metadata for $loadUrl or forcing re-analysis, computing...',
    );

    try {
      final file = await RoasterLogoCacheManager.instance.getSingleFile(
        loadUrl,
        key: cacheKey,
      );
      final bytes = await file.readAsBytes();

      final computedFit = await _computeFit(bytes);
      final computedColor = await _analyzeEdgeLuminance(bytes, isDarkMode);
      final computedIsHorizontal = await _computeIsHorizontal(bytes);

      await _saveFitToCache(cacheKey, computedFit);
      await _saveBgColorToCache(cacheKey, computedColor);
      await _saveIsHorizontalToCache(cacheKey, computedIsHorizontal);

      if (mounted && _currentUrl == loadUrl) {
        setState(() {
          _fit = computedFit;
          _bgColor = computedColor;
          _terminalFailure = false;
        });

        // Notify parent widget about the aspect ratio
        log(
          '📢 Notifying parent widget: computed isHorizontal = $computedIsHorizontal',
        );
        widget.onAspectRatioDetermined?.call(computedIsHorizontal);
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
    // Always wrap in a Stack so the logo's tree position stays stable across
    // _showSteam toggles. If we swapped between `logo` and `Stack([logo, …])`
    // on each tap, the underlying CachedNetworkImage's Element would reattach
    // and the placeholder icon would flash for one frame.
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.passthrough,
        children: [
          _buildLogo(context),
          if (_showSteam) ..._buildSteamPuffs(),
        ],
      ),
    );
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
              child: Icon(Coffeico.bag_with_bean, size: widget.height),
            ),
          );
        }

        if (_currentUrl == null || _terminalFailure) {
          return Icon(Coffeico.bag_with_bean, size: widget.height);
        }

        if (_fit == null) {
          // Still loading
          return SizedBox(
            height: widget.height,
            width: widget.width ?? widget.height,
            child: Center(
              child: Icon(Coffeico.bag_with_bean, size: widget.height),
            ),
          );
        }

        final isSvg = _currentUrl!.toLowerCase().endsWith('.svg');
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
                    ? SvgPicture.network(
                        _currentUrl!,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) =>
                            Icon(Coffeico.bag_with_bean, size: widget.height),
                      )
                    : CachedNetworkImage(
                        cacheKey: _normalizeUrl(_currentUrl!),
                        imageUrl:
                            SupabaseEndpointResolver.localizeStorageUrl(_currentUrl!),
                        cacheManager: RoasterLogoCacheManager.instance,
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            Icon(Coffeico.bag_with_bean, size: widget.height),
                        errorWidget: (context, url, error) {
                          _scheduleHandleError(url);
                          return Icon(
                            Coffeico.bag_with_bean,
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
