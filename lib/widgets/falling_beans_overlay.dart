import 'dart:math' as math;

import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show HapticFeedback;

/// A short-lived "rain of coffee beans" overlay. Beans pour from above at a
/// fixed terminal velocity (with tiny horizontal drift + spin per bean),
/// filling the whole screen for [rainDuration], and then everything fades
/// out together.
///
/// Designed to be dropped into a [Stack] above other content (typically via
/// `Positioned.fill`). Lifecycle:
///
/// 1. **Pre-seed.** The first frame already has beans scattered top-to-bottom
///    so the screen reads as full immediately — no "ramp-up" before the
///    effect feels like rain.
/// 2. **Raining.** New beans continue to spawn at the top at a fixed rate;
///    beans that drift off the bottom are recycled out. The overlay absorbs
///    taps over its full surface — a single tap cuts the rain short.
/// 3. **Fade-out.** Triggered automatically after [rainDuration] or on a
///    user tap. All currently-on-screen beans fade out together over
///    ~0.6s while continuing to fall.
/// 4. **Cycle end.** [onComplete] is called once the last bean has faded.
///    If [cycles] > 1, a fresh wave of rain starts instead.
class FallingBeansOverlay extends StatefulWidget {
  const FallingBeansOverlay({
    super.key,
    this.rainDuration = const Duration(milliseconds: 1800),
    this.cycles = 1,
    this.beanColor,
    this.onComplete,
  });

  /// How long the spawn phase lasts before the fade-out kicks in.
  final Duration rainDuration;

  /// How many waves of rain to play before signalling completion.
  final int cycles;

  /// Tint applied to the bean icons. Defaults to the theme's primary color.
  final Color? beanColor;

  /// Called once the overlay finishes its last cycle.
  final VoidCallback? onComplete;

  @override
  State<FallingBeansOverlay> createState() => _FallingBeansOverlayState();
}

/// Tunable constants. Units are logical pixels and seconds.
const double _kFallSpeed = 600.0; // base downward velocity
const double _kFallSpeedJitter = 220.0; // ± per-bean variance
const double _kHorizontalDriftMax = 40.0; // ± per-bean
const double _kSpawnPerSecond = 50.0;
const double _kFadeInSeconds = 0.18;
const double _kFadeOutSeconds = 0.6;

enum _Phase { raining, fading, done }

class _FallingBeansOverlayState extends State<FallingBeansOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();
  final List<_Bean> _beans = [];
  Duration _lastTick = Duration.zero;
  Duration _cycleStart = Duration.zero;
  Duration _fadeStart = Duration.zero;
  double _spawnAccumulator = 0;
  int _cyclesCompleted = 0;
  Size _lastSize = Size.zero;
  bool _initialized = false;
  _Phase _phase = _Phase.raining;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!_initialized || _lastSize == Size.zero) {
      _lastTick = elapsed;
      return;
    }
    final dtSeconds = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dtSeconds <= 0) return;
    final dt = math.min(dtSeconds, 1.0 / 30.0);

    // Phase transitions
    if (_phase == _Phase.raining &&
        elapsed - _cycleStart >= widget.rainDuration) {
      _startFade(elapsed);
    }

    // Spawn new beans while raining.
    if (_phase == _Phase.raining) {
      _spawnAccumulator += dt * _kSpawnPerSecond;
      while (_spawnAccumulator >= 1) {
        _spawnAccumulator -= 1;
        _beans.add(_spawnTopBean(_lastSize));
      }
    }

    final fadeT = _phase == _Phase.fading
        ? ((elapsed - _fadeStart).inMicroseconds / 1e6) / _kFadeOutSeconds
        : 0.0;

    // Advance all beans.
    _beans.removeWhere((bean) {
      bean.age += dt;
      bean.y += bean.vy * dt;
      bean.x += bean.vx * dt;
      bean.rotation += bean.omega * dt;

      // Fade-in alpha
      final fadeInAlpha = bean.age < _kFadeInSeconds
          ? (bean.age / _kFadeInSeconds).clamp(0.0, 1.0)
          : 1.0;
      // Fade-out alpha (only relevant during fade phase)
      final fadeOutAlpha =
          _phase == _Phase.fading ? (1.0 - fadeT).clamp(0.0, 1.0) : 1.0;
      bean.alpha = fadeInAlpha * fadeOutAlpha;

      // Off-screen below = recycle
      if (bean.y - bean.size > _lastSize.height) return true;
      // Faded fully out
      if (_phase == _Phase.fading && bean.alpha <= 0) return true;
      return false;
    });

    // Cycle end?
    if (_phase == _Phase.fading && _beans.isEmpty) {
      _endCycle(elapsed);
      return;
    }

    if (!_disposed) setState(() {});
  }

  void _startFade(Duration now) {
    _phase = _Phase.fading;
    _fadeStart = now;
  }

  void _endCycle(Duration now) {
    _cyclesCompleted += 1;
    if (_cyclesCompleted >= widget.cycles) {
      _phase = _Phase.done;
      if (mounted) setState(() {});
      _ticker.stop();
      widget.onComplete?.call();
      return;
    }
    // Next cycle: clean slate, fresh rain.
    _phase = _Phase.raining;
    _cycleStart = now;
    _spawnAccumulator = 0;
    _seedFullScreen(_lastSize);
  }

  /// Pre-seed beans scattered top-to-bottom so the very first frame already
  /// looks like rain instead of a thin row of beans at the top.
  void _seedFullScreen(Size size) {
    _beans.clear();
    if (size.width <= 0 || size.height <= 0) return;
    // Density = how many beans should be on screen at steady state.
    // Steady-state count ≈ spawnRate × (screenHeight / averageFallSpeed).
    final steadyCount = (_kSpawnPerSecond * (size.height / _kFallSpeed))
        .round()
        .clamp(20, 80);
    for (var i = 0; i < steadyCount; i++) {
      final bean = _spawnTopBean(size);
      // Push it down to a random initial y throughout the visible area.
      bean.y = _rng.nextDouble() * size.height;
      // Set age past fade-in so pre-seeded beans don't all fade in together.
      bean.age = _kFadeInSeconds;
      bean.alpha = 1.0;
      _beans.add(bean);
    }
  }

  _Bean _spawnTopBean(Size size) {
    final width = size.width <= 0 ? 320.0 : size.width;
    final beanSize = 18.0 + _rng.nextDouble() * 16.0; // 18..34
    return _Bean(
      x: _rng.nextDouble() * width,
      y: -beanSize - _rng.nextDouble() * 20.0,
      vx: (_rng.nextDouble() - 0.5) * 2 * _kHorizontalDriftMax,
      vy: _kFallSpeed + (_rng.nextDouble() - 0.5) * 2 * _kFallSpeedJitter,
      size: beanSize,
      rotation: _rng.nextDouble() * math.pi * 2,
      omega: (_rng.nextDouble() - 0.5) * 5.0, // -2.5..2.5 rad/s
    );
  }

  void _dismiss() {
    if (_phase != _Phase.raining) return;
    HapticFeedback.selectionClick();
    _startFade(_lastTick);
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.done) return const SizedBox.shrink();

    final color = widget.beanColor ?? Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (size != _lastSize) {
          _lastSize = size;
          if (!_initialized && size.width > 0 && size.height > 0) {
            _initialized = true;
            _cycleStart = _lastTick;
            _seedFullScreen(size);
          }
        }
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _dismiss,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final bean in _beans)
                Positioned(
                  left: bean.x - bean.size / 2,
                  top: bean.y - bean.size / 2,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: bean.alpha,
                      child: Transform.rotate(
                        angle: bean.rotation,
                        child: Icon(
                          Coffeico.bean,
                          size: bean.size,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Bean {
  _Bean({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.omega,
  });

  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double omega;
  final double size;
  double age = 0;
  double alpha = 0;
}
