import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../services/onboarding_service.dart';
import '../theme/design_tokens.dart';

class FavoriteButton extends StatefulWidget {
  final String recipeId;

  /// Attention nudge for the journey card's "favorite a recipe" milestone:
  /// while the recipe is not yet a favorite, a soft circular halo sits
  /// behind the heart and the icon pulses a few times (after a short delay,
  /// so the page transition finishes). The halo survives the pulse but any
  /// tap — either direction — removes it for good. Never shown when the
  /// recipe is already a favorite.
  final bool highlight;

  const FavoriteButton({
    super.key,
    required this.recipeId,
    this.highlight = false,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with TickerProviderStateMixin {
  bool _isFavorite = false; // Initialize with a default value
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // --- Highlight feedback (halo + pulse) ---
  /// Delay before the pulse starts so the page transition finishes first.
  static const Duration _pulseDelay = Duration(milliseconds: 400);
  /// One pulse: scale up then back down.
  static const Duration _pulseCycle = Duration(milliseconds: 600);
  static const int _pulseCount = 3;
  /// Halo circle: the 24 pt icon plus a slim ring, well inside the 48 pt
  /// tap target so the 1.2× pulse stays clear of the screen edge.
  static const double _haloDiameter = AppIconSize.large + AppSpacing.xs;

  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  bool _showHalo = false;
  /// Whether the highlight decision has been made (activated, or a tap
  /// cancelled it before the favorite status even resolved). Never
  /// re-evaluated once true.
  bool _highlightDecided = false;

  @override
  void initState() {
    super.initState();
    _initializeFavoriteStatus();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.15)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.15, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50),
    ]).animate(_controller);

    // Finite animation: ~400 ms held at scale 1.0 (the page transition),
    // then [_pulseCount] 1.0 → 1.2 → 1.0 pulses. The controller runs once
    // and stops; the halo itself is static state, not an animation.
    _pulseController = AnimationController(
      vsync: this,
      duration: _pulseDelay + _pulseCycle * _pulseCount,
    );
    // Sequence weights only encode proportions; the controller duration
    // above sets the absolute timing.
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: _pulseDelay.inMilliseconds.toDouble(),
      ),
      for (var i = 0; i < _pulseCount; i++) ...[
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.2)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: (_pulseCycle.inMilliseconds ~/ 2).toDouble(),
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.2, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: (_pulseCycle.inMilliseconds ~/ 2).toDouble(),
        ),
      ],
    ]).animate(_pulseController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeFavoriteStatus() async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final recipe = await recipeProvider.getRecipeById(widget.recipeId);
    if (mounted) {
      setState(() {
        _isFavorite = recipe?.isFavorite ?? false;
      });
      _maybeStartHighlightFeedback();
    }
  }

  /// Shows the halo (and starts the pulse, unless the user disabled
  /// animations) once the favorite status is known: only when opened with
  /// [FavoriteButton.highlight] and the recipe is not already a favorite.
  void _maybeStartHighlightFeedback() {
    if (!widget.highlight || _isFavorite || _highlightDecided) return;
    _highlightDecided = true;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    setState(() => _showHalo = true);
    if (!reducedMotion) {
      _pulseController.forward();
    }
  }

  Future<void> _toggleFavorite() async {
    // The halo is the "try me" nudge — any tap, either direction, ends it
    // (and any running pulse) for good.
    if (_showHalo) {
      setState(() => _showHalo = false);
      _pulseController.reset();
      _highlightDecided = true;
    }

    final recipeProvider =
        Provider.of<RecipeProvider>(context, listen: false);
    await recipeProvider.toggleFavorite(widget.recipeId);
    if (!mounted) return;

    final recipe = await recipeProvider.getRecipeById(widget.recipeId);
    if (!mounted) return;

    bool newStatus = recipe?.isFavorite ?? false;
    setState(() {
      _isFavorite = newStatus;
    });
    // If changed to favorite, trigger the pop-up scale animation.
    if (newStatus) {
      _controller.forward(from: 0.0);
      Provider.of<OnboardingService>(context, listen: false)
          .completeMilestoneFavorite();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The tree shape never changes with the highlight state: the halo is a
    // DecoratedBox that is always present, its decoration animating between
    // transparent and the soft primary tint. Changing the widget type at
    // this position would remount the button and re-run initState.
    return ScaleTransition(
      scale: _pulseScale,
      child: ScaleTransition(
        scale: _scaleAnimation,
        // The halo is smaller than the 48 pt tap target and centred on the
        // icon: in the recipe app bar the heart is the last action, flush
        // with the screen edge, so a target-sized halo (and its 1.2× pulse)
        // ran into the edge and looked clipped.
        child: Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              child: SizedBox.square(
                dimension: _haloDiameter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _showHalo
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.15)
                        : null,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite
                    ? (Theme.of(context).brightness == Brightness.light
                        ? const Color(0xff8e2e2d)
                        : const Color(0xffc66564))
                    : null,
              ),
              onPressed: _toggleFavorite,
            ),
          ],
        ),
      ),
    );
  }
}
