import 'dart:async';
import 'dart:math'; // for pi, sin
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io'; // For file handling
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:path_provider/path_provider.dart'; // For temporary directory
import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage
import 'package:coffee_timer/l10n/app_localizations.dart'; // Import localization
import 'package:flutter/foundation.dart' show kIsWeb;
import '../app_router.gr.dart';
import '../providers/user_stat_provider.dart';
import '../providers/coffee_beans_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/database_provider.dart'; // Import DatabaseProvider
import '../utils/icon_utils.dart'; // Import the icon utility
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:coffeico/coffeico.dart';

// Moved helper classes to top-level

// --------------------------------------
class _StoryData {
  final double totalLiters;
  final int distinctRoasterCount;
  final List<String> top3Roasters;
  final int distinctOriginCount;
  final List<String> distinctMethods;
  final Map<String, String> methodIdToName;
  final List<RecipeModel> top3Recipes;

  _StoryData({
    required this.totalLiters,
    required this.distinctRoasterCount,
    required this.top3Roasters,
    required this.distinctOriginCount,
    required this.distinctMethods,
    required this.methodIdToName,
    required this.top3Recipes,
  });
}

// --------------------------------------
class _StoryConfig {
  final Duration duration;
  final VoidCallback onStart;
  final Widget Function(
    BuildContext context,
    ColorScheme colorScheme,
    _StoryData data,
  ) builder;

  _StoryConfig({
    required this.duration,
    required this.builder,
    this.onStart = _defaultStart,
  });

  static void _defaultStart() {}
}

@RoutePage()
class YearlyStatsStoryScreen extends StatefulWidget {
  const YearlyStatsStoryScreen({Key? key}) : super(key: key);

  @override
  State<YearlyStatsStoryScreen> createState() => _YearlyStatsStoryScreenState();
}

class _YearlyStatsStoryScreenState extends State<YearlyStatsStoryScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------
  // Story data we fetch:
  //   1) total liters of coffee in 2024
  //   2) number of distinct roasters (and top 3)
  //   3) number of distinct origins
  //   4) distinct brewing methods used
  //   5) top-3 recipes
  // ---------------------------------------------------------

  late Future<_StoryData> _futureStoryData;

  // Main progress controller for advancing each story
  late AnimationController _progressController;

  // Story #1: Disco lights
  late AnimationController _discoController;
  late Animation<Color?> _discoColor;

  // Story #2: Ellipsis #1
  late AnimationController _ellipsisController;

  // Story #3: Count-up
  late AnimationController _countUpController;
  late Animation<double> _countUpAnimation;
  bool _isCountUpDone = false;

  // Story #4: fade in second text
  bool _showSecondPart4 = false;
  Timer? _delayedTimer4;

  // Story #5: Ellipsis #2
  late AnimationController _ellipsisController2;

  // Story #6: Earth GIF
  // No special controller needed, just place the GIF

  // Story #7: fade and slide second text
  bool _showSecondPart7 = false;
  Timer? _delayedTimer7;
  late AnimationController _slideController7;
  late Animation<Offset> _slideAnimation7;
  late Animation<double> _fadeAnimation7;

  // Story #8: Brewing methods
  late AnimationController _methodsController;
  int _visibleMethodCount = 0;
  Timer? _methodsTimer;
  List<String>? _currentMethods;

  // Story #10: Top-3 recipes
  late AnimationController _ellipsisController3;
  late AnimationController _fadeController;
  bool _showPodium = false;
  Timer? _delayedTimer10;

  // Current story index
  int _currentStoryIndex = 0;

  // We will have 11 stories total
  late final List<_StoryConfig> _stories;

  // -----------------------------------------
  // New State Variables for Likes
  // -----------------------------------------
  int _likesCount = 0;
  late StreamSubscription<List<Map<String, dynamic>>> _likesSubscription;

  // Add this overlay entry field
  OverlayEntry? _shareOverlay;

  @override
  void initState() {
    super.initState();

    // 1) Fetch story data
    _futureStoryData = _fetchStoryData();

    // 2) Progress controller
    _progressController = AnimationController(
      vsync: this,
      duration: Duration.zero, // will set dynamically per story
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _goToNextStory();
        }
      });

    // 3) Disco
    _discoController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _discoColor = ColorTween(begin: Colors.pink, end: Colors.purple)
        .animate(_discoController);

    // 4) Ellipsis #1
    _ellipsisController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..addListener(() => setState(() {}))
      ..repeat();

    // 5) Count-up
    _countUpController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _countUpAnimation = Tween<double>(begin: 0, end: 0)
        .animate(_countUpController)
      ..addListener(() => setState(() {}));
    _countUpController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isCountUpDone = true);
      }
    });

    // 6) Ellipsis #2
    _ellipsisController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..addListener(() => setState(() {}))
      ..repeat();

    // 7) For story #7: slide and fade animation
    _slideController7 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation7 = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController7,
      curve: Curves.easeOut,
    ));
    _fadeAnimation7 = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController7,
      curve: Curves.easeIn,
    ));

    _methodsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // increased from 500ms
    )..addListener(() => setState(() {}));

    // 10) Top-3 recipes
    _ellipsisController3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..addListener(() => setState(() {}))
      ..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 8) Define stories
    _stories = [
      // ------------------ Story #1: Disco (5s) ------------------
      _StoryConfig(
        duration: const Duration(seconds: 5),
        onStart: () {
          // Already repeating disco
        },
        builder: (context, colorScheme, data) {
          return AnimatedBuilder(
            animation: _discoController,
            builder: (_, __) => Container(
              color: _discoColor.value ?? Colors.black,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              child: Text(
                AppLocalizations.of(context)!.yearlyStatsStory1Text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),

      // ------------------ Story #2: Ellipsis #1 (5s) ------------------
      _StoryConfig(
        duration: const Duration(seconds: 5),
        onStart: () {
          // ellipsis #1 repeating
        },
        builder: (context, colorScheme, data) {
          final t = _ellipsisController.value % 1.0;
          final ellipsis = (t < 0.33)
              ? '.'
              : (t < 0.66)
                  ? '..'
                  : '...';

          return Container(
            color: colorScheme.surface,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20),
            child: Text(
              AppLocalizations.of(context)!.yearlyStatsStory2Text(ellipsis),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          );
        },
      ),

      // ------------------ Story #3: Count-up (10s) ------------------
      _StoryConfig(
        duration: const Duration(seconds: 10),
        onStart: () {
          _isCountUpDone = false;
          _countUpController.reset();
          _countUpController.forward();
        },
        builder: (context, colorScheme, data) {
          final currentValue =
              _isCountUpDone ? data.totalLiters : _countUpAnimation.value;
          return Container(
            color: colorScheme.surface,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20),
            child: Text(
              AppLocalizations.of(context)!
                  .yearlyStatsStory3Text(currentValue.toStringAsFixed(2)),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),

      // ------------------ Story #4: fade in second text (10s) ------------------
      _StoryConfig(
        duration: const Duration(seconds: 10),
        onStart: () {
          _showSecondPart4 = false;
          _delayedTimer4?.cancel();
          _delayedTimer4 = Timer(const Duration(seconds: 2), () {
            setState(() => _showSecondPart4 = true);
          });
        },
        builder: (context, colorScheme, data) {
          // black bg, white text
          final bgColor = Colors.black;
          final textColor = Colors.white;
          final top3 =
              data.top3Roasters.isEmpty ? '' : data.top3Roasters.join(', ');

          return Container(
            color: bgColor,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!
                      .yearlyStatsStory4Text(data.distinctRoasterCount),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedOpacity(
                  duration: const Duration(seconds: 1),
                  opacity: _showSecondPart4 ? 1.0 : 0.0,
                  child: Text(
                    AppLocalizations.of(context)!
                        .yearlyStatsStory4Top3Roasters(top3),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 24,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // ------------------ Story #5: "Coffee took you..." (5s) with ellipsis #2 ------------------
      _StoryConfig(
        duration: const Duration(seconds: 5),
        onStart: () {
          // already repeating
        },
        builder: (context, colorScheme, data) {
          final t = _ellipsisController2.value % 1.0;
          final ellipsis = (t < 0.33)
              ? '.'
              : (t < 0.66)
                  ? '..'
                  : '...';

          return Container(
            color: colorScheme.surface,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20),
            child: Text(
              AppLocalizations.of(context)!.yearlyStatsStory5Text(ellipsis),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          );
        },
      ),

      // ------------------ Story #6: Earth Animation (10s) ------------------
      _StoryConfig(
        duration: const Duration(seconds: 5),
        onStart: () {
          // no special controller, just show the animation
        },
        builder: (context, colorScheme, data) {
          return Container(
            color: Colors.black, // black background
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      AppLocalizations.of(context)!
                          .yearlyStatsStory6Text(data.distinctOriginCount),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // white text
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Lottie.asset(
                    'assets/coffee_beans.json',
                    width: 200, // Adjust the size as needed
                    height: 200, // Adjust the size as needed
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // ------------------ Story #7: two-part text with fade and slide-up (10s) ------------------
      _StoryConfig(
        duration: const Duration(seconds: 10),
        onStart: () {
          _showSecondPart7 = false;
          _slideController7.reset();
          _delayedTimer7?.cancel();
          // After 1s, fade and slide in second line
          _delayedTimer7 = Timer(const Duration(seconds: 1), () {
            setState(() => _showSecondPart7 = true);
            _slideController7.forward();
          });
        },
        builder: (context, colorScheme, data) {
          final bgColor = colorScheme.surface;
          final textColor = colorScheme.onSurface;

          return Container(
            color: bgColor,
            alignment: Alignment.center,
            child: Stack(
              children: [
                // Earth animation at the bottom
                Positioned(
                  bottom: 20, // Adjusted to be closer to bottom
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _showSecondPart7 ? 1.0 : 0.0,
                    duration: const Duration(seconds: 1),
                    child: Lottie.asset(
                      'assets/earth.json',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                ),
                // Text container with padding to avoid overlap
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 240),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.yearlyStatsStory7Part1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SlideTransition(
                        position: _slideAnimation7,
                        child: FadeTransition(
                          opacity: _fadeAnimation7,
                          child: Text(
                            AppLocalizations.of(context)!
                                .yearlyStatsStory7Part2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'RobotoMono',
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // ------------------ Story #8: Brewing methods (10s) ------------------
      _StoryConfig(
        duration: const Duration(seconds: 10),
        onStart: () {
          // Reset the visible count and start showing methods
          setState(() {
            _visibleMethodCount = 0;
            _currentMethods = null;
          });
          _methodsTimer?.cancel();
          _methodsController.reset();

          void showNextMethod() {
            if (_currentMethods == null) return;

            if (_visibleMethodCount < _currentMethods!.length) {
              setState(() => _visibleMethodCount++);
              _methodsController.forward(from: 0.0);

              // Schedule next method if there are more
              if (_visibleMethodCount < _currentMethods!.length) {
                // Calculate remaining time and adjust delay
                final remainingMethods =
                    _currentMethods!.length - _visibleMethodCount;
                // Reserve 2.5 seconds at the end for viewing all methods
                final remainingTime =
                    _progressController.duration!.inMilliseconds *
                            (1 - _progressController.value) -
                        2500;
                final delay =
                    (remainingTime / remainingMethods).clamp(800, 2000).toInt();

                _methodsTimer = Timer(
                  Duration(milliseconds: delay),
                  showNextMethod,
                );
              }
            }
          }

          // Start the sequence after a brief delay
          _methodsTimer = Timer(
            const Duration(milliseconds: 800), // increased initial delay
            showNextMethod,
          );
        },
        builder: (context, colorScheme, data) {
          // Store the current methods at build time
          if (_currentMethods != data.distinctMethods) {
            _currentMethods = data.distinctMethods;
          }

          final bgColor = colorScheme.surface;
          final textColor = colorScheme.onSurface;

          final count = data.distinctMethods.length;
          String title;
          if (count <= 2) {
            title =
                AppLocalizations.of(context)!.yearlyStatsStory8TitleLow(count);
          } else if (count <= 5) {
            title = AppLocalizations.of(context)!
                .yearlyStatsStory8TitleMedium(count);
          } else {
            title =
                AppLocalizations.of(context)!.yearlyStatsStory8TitleHigh(count);
          }

          // Fetch icons only once
          final icons = data.distinctMethods.map((methodId) {
            return getIconByBrewingMethod(methodId);
          }).toList();

          return Container(
            color: bgColor,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                // Show a wrap of methods with icons
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: data.distinctMethods.asMap().entries.map((entry) {
                    final index = entry.key;
                    final methodId = entry.value;
                    final icon = icons[index];
                    final methodName = data.methodIdToName[methodId] ??
                        AppLocalizations.of(context)!.yearlyStatsUnknown;

                    // Only show if this method should be visible
                    if (index >= _visibleMethodCount) {
                      return const SizedBox.shrink();
                    }

                    // If this is the latest method, animate it
                    final isLatest = index == _visibleMethodCount - 1;
                    final opacity = isLatest
                        ? CurvedAnimation(
                            parent: _methodsController,
                            curve: Curves.easeInOut,
                          ).value
                        : 1.0;

                    return Opacity(
                      opacity: opacity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          icon,
                          const SizedBox(height: 4),
                          Text(
                            methodName,
                            style: TextStyle(
                              fontFamily: 'RobotoMono',
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),

      // ------------------ Story #9: "So much else to discover!" (5s) ------------------
      _StoryConfig(
        duration: const Duration(seconds: 5),
        onStart: () {
          // No special controller needed
        },
        builder: (context, colorScheme, data) {
          return Container(
            color: Colors.black,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20),
            child: Text(
              AppLocalizations.of(context)!.yearlyStatsStory9Text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        },
      ),

      // ------------------ Story #10: Top-3 recipes (10s) ------------------
      _StoryConfig(
        duration: const Duration(seconds: 10),
        onStart: () {
          _showPodium = false;
          _fadeController.reset();
          _delayedTimer10?.cancel();
          _delayedTimer10 = Timer(const Duration(seconds: 2), () {
            setState(() => _showPodium = true);
            _fadeController.forward();
          });
        },
        builder: (context, colorScheme, data) {
          final t = _ellipsisController3.value % 1.0;
          final ellipsis = (t < 0.33)
              ? '.'
              : (t < 0.66)
                  ? '..'
                  : '...';

          return Stack(
            fit: StackFit.expand, // Ensure the stack fills the screen
            children: [
              Container(
                color: Colors.black, // True black background
                alignment: Alignment.center,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!
                          .yearlyStatsStory10Text(ellipsis),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Set text color to white
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 800),
                      opacity: _showPodium ? 1.0 : 0.0,
                      child: _buildPodium(context, data.top3Recipes),
                    ),
                  ],
                ),
              ),
              // Top fireworks
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Lottie.asset(
                  'assets/fireworks.json',
                  fit: BoxFit.cover,
                  repeat: true,
                ),
              ),
              // Bottom fireworks
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Lottie.asset(
                  'assets/fireworks.json',
                  fit: BoxFit.cover,
                  repeat: true,
                ),
              ),
            ],
          );
        },
      ),
      // ------------------ Story #11: Final screen (no auto-advance) ------------------
      _StoryConfig(
        duration: const Duration(
            days: 1), // Very long duration since we don't want auto-advance
        onStart: () {
          // Stop the progress controller to prevent auto-advance
          _progressController.stop();
        },
        builder: (context, colorScheme, data) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background with coffee emoji pattern
              Positioned.fill(
                child: Container(
                  color: Colors.white,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const int crossAxisCount = 6;
                      const double mainAxisSpacing = 20;
                      const double crossAxisSpacing = 20;

                      final double itemWidth = (constraints.maxWidth -
                              (crossAxisCount - 1) * crossAxisSpacing) /
                          crossAxisCount;
                      final double itemHeight = itemWidth;

                      final int numberOfRows =
                          ((constraints.maxHeight + mainAxisSpacing) /
                                  (itemHeight + mainAxisSpacing))
                              .ceil();

                      final int itemCount = crossAxisCount * numberOfRows;

                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: mainAxisSpacing,
                          crossAxisSpacing: crossAxisSpacing,
                          childAspectRatio: itemWidth / itemHeight,
                        ),
                        itemBuilder: (context, index) {
                          return Transform.rotate(
                            angle: (index * pi / 6) % (2 * pi),
                            child: const Center(
                              child: Text(
                                '☕',
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        },
                        itemCount: itemCount,
                      );
                    },
                  ),
                ),
              ),

              // Content Layer
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Close button at the top
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTapDown: (_) {}, // Prevent tap from propagating
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 4,
                            shape: const CircleBorder(),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.black,
                            size: 32,
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Centered text with semi-transparent background
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .yearlyStatsFinalText,
                                  style: const TextStyle(
                                    fontFamily: 'RobotoMono',
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Action buttons wrapped in GestureDetector to prevent story navigation
                            GestureDetector(
                              onTapDown: (_) {}, // Prevent tap from propagating
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Show some love button with likes count
                                  _buildActionButton(
                                    AppLocalizations.of(context)!
                                        .yearlyStatsActionLove(_likesCount),
                                    Icons.favorite,
                                    onPressed: () {
                                      _incrementLikes();
                                    },
                                    isLoveButton: true,
                                  ),

                                  const SizedBox(height: 16),

                                  // Donate button
                                  _buildActionButton(
                                    AppLocalizations.of(context)!
                                        .yearlyStatsActionDonate,
                                    Icons.volunteer_activism,
                                    onPressed: () {
                                      context.router
                                          .push(const DonationRoute());
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Share your progress button (hide on web)
                                  if (!kIsWeb)
                                    _buildActionButton(
                                      AppLocalizations.of(context)!
                                          .yearlyStatsActionShare,
                                      Icons.share,
                                      onPressed: () => _handleShare(data),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ];

    // 9) Fetch initial likes count
    _fetchInitialLikes();

    // 10) Subscribe to real-time updates
    _subscribeToLikesUpdates();
  }

  // ------------------------------------------------------
  // For story #8, fetch distinct brewing methods
  // ------------------------------------------------------
  Future<_StoryData> _fetchStoryData() async {
    final userStatProvider =
        Provider.of<UserStatProvider>(context, listen: false);
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);

    // 1) total liters
    final startOf2024 = DateTime(2024, 1, 1);
    final startOf2025 = DateTime(2025, 1, 1);
    final totalMl = await userStatProvider.fetchBrewedCoffeeAmountForPeriod(
      startOf2024,
      startOf2025,
    );
    final totalLiters = totalMl / 1000.0;

    // 2) Distinct roasters used in 2024 (and top 3)
    final userStatsAll = await userStatProvider.fetchAllUserStats();
    final statsFor2024 = userStatsAll
        .where((s) =>
            !s.isDeleted &&
            s.createdAt.isAfter(startOf2024) &&
            s.createdAt.isBefore(startOf2025))
        .toList();

    // Build a map from coffeeBeansUuid -> roaster
    final allBeans = await coffeeBeansProvider.fetchAllCoffeeBeans();
    final beansMap = {
      for (var b in allBeans)
        if (b.beansUuid != null && b.roaster != null) b.beansUuid!: b.roaster!
    };
    // Count roasters
    final Map<String, int> roasterCount = {};
    for (final stat in statsFor2024) {
      final uuid = stat.coffeeBeansUuid ?? '';
      final roasterName = beansMap[uuid];
      if (roasterName != null && roasterName.isNotEmpty) {
        roasterCount[roasterName] = (roasterCount[roasterName] ?? 0) + 1;
      }
    }
    final distinctRoasters = roasterCount.keys.toList();
    distinctRoasters.sort(
      (a, b) => roasterCount[b]!.compareTo(roasterCount[a]!),
    );
    final top3 = distinctRoasters.take(3).toList();

    // 3) Distinct origins
    final distinctOrigins = await coffeeBeansProvider.fetchAllDistinctOrigins();
    final originCount = distinctOrigins.length;

    // 4) Distinct brewing methods
    final Set<String> methodIds = {};
    final Map<String, String> methodIdToName = {};
    for (final stat in statsFor2024) {
      final recipeId = stat.recipeId;
      if (recipeId.isEmpty) continue;
      try {
        final recipe = await recipeProvider.getRecipeById(recipeId);
        if (recipe != null) {
          // Add null check
          final methodId = recipe.brewingMethodId;
          methodIds.add(methodId);
          if (!methodIdToName.containsKey(methodId)) {
            final methodName =
                await recipeProvider.getBrewingMethodName(methodId);
            methodIdToName[methodId] = methodName;
          }
        }
      } catch (_) {
        // ignore if recipe not found or error
      }
    }

    // 5) Top-3 recipes
    final top3RecipeIds = await userStatProvider.fetchTopRecipeIdsForPeriod(
      startOf2024,
      startOf2025,
    );
    // Fetch recipes, which might be null
    final top3RecipesNullable = await Future.wait(
      top3RecipeIds.map((id) => recipeProvider.getRecipeById(id)),
    );
    // Filter out nulls before passing to _StoryData
    final top3Recipes = top3RecipesNullable.whereType<RecipeModel>().toList();

    return _StoryData(
      totalLiters: totalLiters,
      distinctRoasterCount: distinctRoasters.length,
      top3Roasters: top3,
      distinctOriginCount: originCount,
      distinctMethods: methodIds.toList()..sort(),
      methodIdToName: methodIdToName,
      top3Recipes: top3Recipes,
    );
  }

  // -----------------------------------------
  // Fetch Initial Likes Count
  // -----------------------------------------
  Future<void> _fetchInitialLikes() async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('yearly_stats')
          .select()
          .eq('id', 'likes')
          .single();

      if (response != null) {
        setState(() {
          _likesCount = response['count'] ?? 0;
        });
      }
    } catch (e) {
      AppLogger.error('Error fetching likes count', errorObject: e);
      setState(() {
        _likesCount = 0;
      });
    }
  }

  // -----------------------------------------
  // Subscribe to Real-time Updates
  // -----------------------------------------
  void _subscribeToLikesUpdates() {
    final supabase = Supabase.instance.client;

    _likesSubscription = supabase
        .from('yearly_stats')
        .stream(primaryKey: ['id'])
        .eq('id', 'likes')
        .listen(
          (data) {
            if (data.isNotEmpty) {
              setState(() {
                _likesCount = data.first['count'] ?? 0;
              });
            }
          },
          onError: (error) {
            AppLogger.error('Error in likes subscription', errorObject: error);
          },
        );
  }

  // -----------------------------------------
  // Increment Likes Count
  // -----------------------------------------
  Future<void> _incrementLikes() async {
    final supabase = Supabase.instance.client;

    // Optimistic update
    setState(() {
      _likesCount += 1;
    });

    try {
      await supabase.rpc('increment_likes');
      // Success! No need to check response since it's void
    } catch (e) {
      // Rollback optimistic update only on actual error
      setState(() {
        _likesCount -= 1;
      });

      AppLogger.error('Error incrementing likes', errorObject: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.yearlyStatsFailedToLike),
        ),
      );
    }
  }

  @override
  void dispose() {
    _likesSubscription.cancel();

    _discoController.dispose();
    _ellipsisController.dispose();
    _ellipsisController2.dispose();
    _ellipsisController3.dispose();
    _countUpController.dispose();
    _slideController7.dispose();
    _fadeController.dispose();
    _progressController.dispose();
    _delayedTimer4?.cancel();
    _delayedTimer7?.cancel();
    _delayedTimer10?.cancel();
    _methodsTimer?.cancel();
    _methodsController.dispose();
    _shareOverlay?.remove();
    super.dispose();
  }

  // -----------------------------------------
  // Main flow for changing stories
  // -----------------------------------------
  void _startStory(int index) {
    final story = _stories[index];
    story.onStart();

    _progressController.stop();
    _progressController.reset();
    _progressController.duration = story.duration;
    _progressController.forward();
  }

  void _goToNextStory() {
    if (_currentStoryIndex < _stories.length - 1) {
      setState(() => _currentStoryIndex++);
      _startStory(_currentStoryIndex);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goToPreviousStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _startStory(_currentStoryIndex);
    }
  }

  // -----------------------------------------
  // Pause / Resume all animations + progress
  // -----------------------------------------
  void _pauseAllAnimations() {
    _progressController.stop();
    if (_discoController.isAnimating) _discoController.stop();
    if (_ellipsisController.isAnimating) _ellipsisController.stop();
    if (_countUpController.isAnimating) _countUpController.stop();
    if (_ellipsisController2.isAnimating) _ellipsisController2.stop();
    if (_ellipsisController3.isAnimating) _ellipsisController3.stop();
    if (_slideController7.isAnimating) _slideController7.stop();
    if (_fadeController.isAnimating) _fadeController.stop();
    _delayedTimer4?.cancel();
    _delayedTimer7?.cancel();
    _delayedTimer10?.cancel();
    _methodsTimer?.cancel();
    if (_methodsController.isAnimating) _methodsController.stop();
  }

  void _resumeAllAnimations() {
    _progressController.forward();

    // #1 disco
    if (_currentStoryIndex == 0) {
      _discoController.repeat(reverse: true);
    }
    // #2 ellipsis
    if (_currentStoryIndex == 1) {
      _ellipsisController.repeat();
    }
    // #3 count-up
    if (_currentStoryIndex == 2 && !_isCountUpDone) {
      _countUpController.forward();
    }
    // #4 fade
    if (_currentStoryIndex == 3 && !_showSecondPart4) {
      final timeLeft = 2.0 - (2.0 * _progressController.value);
      if (timeLeft > 0) {
        _delayedTimer4 = Timer(
          Duration(milliseconds: (timeLeft * 1000).floor()),
          () => setState(() => _showSecondPart4 = true),
        );
      }
    }
    // #5 ellipsis #2
    if (_currentStoryIndex == 4) {
      _ellipsisController2.repeat();
    }
    // #6 earth gif => no direct animation
    // #7 scale and slide
    if (_currentStoryIndex == 6 && !_showSecondPart7) {
      final timeLeft = 2.0 - (2.0 * _progressController.value);
      if (timeLeft > 0) {
        _delayedTimer7 = Timer(
          Duration(milliseconds: (timeLeft * 1000).floor()),
          () {
            setState(() => _showSecondPart7 = true);
            _slideController7.forward();
          },
        );
      }
    }
    // #10 top-3 recipes
    if (_currentStoryIndex == 9 && !_showPodium) {
      final timeLeft = 2.0 - (2.0 * _progressController.value);
      if (timeLeft > 0) {
        _delayedTimer10 = Timer(
          Duration(milliseconds: (timeLeft * 1000).floor()),
          () {
            setState(() => _showPodium = true);
            _fadeController.forward();
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final colorScheme = isLight
        ? theme.colorScheme.copyWith(brightness: Brightness.dark)
        : theme.colorScheme.copyWith(brightness: Brightness.light);

    final localizations = AppLocalizations.of(context)!;

    return Theme(
      data: theme.copyWith(colorScheme: colorScheme),
      child: Scaffold(
        appBar: AppBar(title: Text(localizations.yearlyStatsAppBarTitle)),
        body: FutureBuilder<_StoryData>(
          future: _futureStoryData,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!;
            final story = _stories[_currentStoryIndex];

            // Update the count-up tween's end value each build
            _countUpAnimation = Tween<double>(begin: 0, end: data.totalLiters)
                .animate(_countUpController);

            // Ensure the story starts once
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_progressController.duration == Duration.zero) {
                _startStory(_currentStoryIndex);
              }
            });

            // Multiple progress bars
            final progressBars = <Widget>[];
            for (var i = 0; i < _stories.length; i++) {
              double value;
              if (i < _currentStoryIndex) {
                value = 1.0; // fully done
              } else if (i > _currentStoryIndex) {
                value = 0.0; // not started
              } else {
                // the current story
                value = _progressController.value;
              }

              progressBars.add(
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 4,
                      backgroundColor: colorScheme.onSurface.withOpacity(0.3),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.onSurface),
                    ),
                  ),
                ),
              );
            }

            // We'll wrap the content in a GestureDetector, but exclude the final story
            Widget content = Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 4.0,
                  ),
                  child: Row(children: progressBars),
                ),
                Expanded(
                  child: story.builder(context, colorScheme, data),
                ),
              ],
            );

            // Only add gesture detection if not on the final story
            if (_currentStoryIndex < _stories.length - 1) {
              content = GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  final width = MediaQuery.of(context).size.width;
                  final dx = details.localPosition.dx;
                  if (dx < width / 2) {
                    _goToPreviousStory();
                  } else {
                    _goToNextStory();
                  }
                },
                onLongPressStart: (_) => _pauseAllAnimations(),
                onLongPressEnd: (_) => _resumeAllAnimations(),
                child: content,
              );
            }

            return content;
          },
        ),
      ),
    );
  }

  // --------------------------------------
  // Build the victory podium widget
  // --------------------------------------
  Widget _buildPodium(BuildContext context, List<RecipeModel> recipes) {
    final localizations = AppLocalizations.of(context)!;

    // Define custom colors
    final Color gold = const Color(0xFFFFD700);
    final Color silver = const Color(0xFFC0C0C0);
    final Color bronze = const Color(0xFFCD7F32);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First place (Gold)
        AnimatedOpacity(
          opacity: _showPodium ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 3000),
          child: Row(
            children: [
              Icon(Icons.emoji_events, size: 30, color: gold),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  recipes.isNotEmpty
                      ? recipes[0].name
                      : localizations.yearlyStatsUnknown,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Set text color to white
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Second place (Silver)
        AnimatedOpacity(
          opacity: _showPodium ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 2000),
          child: Row(
            children: [
              Icon(Icons.emoji_events, size: 30, color: silver),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  recipes.length > 1
                      ? recipes[1].name
                      : localizations.yearlyStatsUnknown,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Set text color to white
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Third place (Bronze)
        AnimatedOpacity(
          opacity: _showPodium ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 800),
          child: Row(
            children: [
              Icon(Icons.emoji_events, size: 30, color: bronze),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  recipes.length > 2
                      ? recipes[2].name
                      : localizations.yearlyStatsUnknown,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Set text color to white
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------
  // Updated Action Button Builder
  // --------------------------------------
  Widget _buildActionButton(
    String text,
    IconData icon, {
    required VoidCallback onPressed,
    double? fontSize,
    bool isLoveButton = false,
  }) {
    // Let's check if the button is meant to "Share"
    final shareLabel = AppLocalizations.of(context)!.yearlyStatsActionShare;
    IconData finalIcon = icon;

    if (text == shareLabel) {
      if (kIsWeb) {
        // On the web, just use the generic share icon
        finalIcon = Icons.share;
      } else {
        // On other platforms, check for iOS or Android
        if (Platform.isAndroid) {
          finalIcon = Icons.share_rounded;
        } else if (Platform.isIOS) {
          finalIcon = CupertinoIcons.share;
        } else {
          // Fallback for e.g. Windows, macOS, Linux
          finalIcon = Icons.share;
        }
      }
    }

    // If it's a "love" button, we show hearts, etc.
    if (isLoveButton) {
      return _ShakingLoveButton(
        text: text,
        icon: finalIcon,
        onPressed: onPressed,
        fontSize: fontSize,
      );
    }

    return AbsorbPointer(
      absorbing: false,
      child: Semantics(
        button: true,
        label: text,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(finalIcon, size: 24),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize ?? 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add this new method
  Future<void> _handleShare(_StoryData data) async {
    // Create a transparent overlay that covers the screen
    final overlayState = Overlay.of(context);
    final GlobalKey repaintBoundaryKey = GlobalKey();

    _shareOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Center(
          child: ShareProgressWidget(
            data: data,
            repaintBoundaryKey: repaintBoundaryKey,
            onReadyToCapture: () async {
              // Once all images are loaded and rendered, capture and share
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                // Add a slight delay to ensure rendering is complete
                await Future.delayed(const Duration(milliseconds: 1000));
                await _captureAndShare(repaintBoundaryKey, data);
                // Remove the overlay after sharing
                _shareOverlay?.remove();
                _shareOverlay = null;
              });
            },
          ),
        ),
      ),
    );

    overlayState.insert(_shareOverlay!);

    // No need for a fixed delay; the callback handles the timing
  }

  Future<void> _captureAndShare(GlobalKey key, _StoryData data) async {
    final localizations = AppLocalizations.of(context)!;

    try {
      RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception(localizations.unexpectedErrorOccurred);
      }

      // Capture the image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception(localizations.unexpectedErrorOccurred);
      }
      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to a temporary file with .png extension
      final tempDir = await getTemporaryDirectory();
      final file =
          await File('${tempDir.path}/timer_coffee_stats.png').create();
      await file.writeAsBytes(pngBytes);

      // Create XFile with explicit MIME type
      final xFile = XFile(
        file.path,
        mimeType: 'image/png',
        name: 'timer_coffee_stats.png',
      );

      // Share the image
      await Share.shareXFiles([xFile]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.yearlyStatsErrorSharing(e.toString())),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      AppLogger.error('Share progress error', errorObject: e);
    }
  }
}

// Moved helper classes outside _YearlyStatsStoryScreenState

class ShareProgressWidget extends StatefulWidget {
  final _StoryData data;
  final GlobalKey repaintBoundaryKey;
  final VoidCallback onReadyToCapture; // Added callback

  const ShareProgressWidget({
    Key? key,
    required this.data,
    required this.repaintBoundaryKey,
    required this.onReadyToCapture, // Initialize the callback
  }) : super(key: key);

  @override
  State<ShareProgressWidget> createState() => _ShareProgressWidgetState();
}

class _ShareProgressWidgetState extends State<ShareProgressWidget> {
  late Future<Map<String, Map<String, String?>>> _roasterLogosFuture;
  int _totalLogos = 0;
  int _loadedLogos = 0;
  bool _allLogosHandled = false;

  @override
  void initState() {
    super.initState();
    _roasterLogosFuture = _fetchRoasterLogos();
    // If there are no roasters, trigger the capture callback immediately
    if (widget.data.top3Roasters.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onReadyToCapture();
      });
    }
  }

  /// Fetches both original and mirror logo URLs for each roaster.
  Future<Map<String, Map<String, String?>>> _fetchRoasterLogos() async {
    if (widget.data.top3Roasters.isEmpty) {
      return {}; // Return empty map for no roasters
    }

    final databaseProvider =
        Provider.of<DatabaseProvider>(context, listen: false);
    final Map<String, Map<String, String?>> roasterLogos = {};

    for (String roaster in widget.data.top3Roasters) {
      final logos = await databaseProvider.fetchCachedRoasterLogoUrls(roaster);
      roasterLogos[roaster] = logos; // Contains 'original' and 'mirror'
    }

    setState(() {
      _totalLogos = roasterLogos.length;
    });

    return roasterLogos;
  }

  void _checkAllLogosHandled() {
    if (!_allLogosHandled && _loadedLogos >= _totalLogos) {
      _allLogosHandled = true;
      // Schedule the callback after the current frame to ensure rendering
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onReadyToCapture();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = screenHeight * 0.05;

    final localizations = AppLocalizations.of(context)!;

    return RepaintBoundary(
        key: widget.repaintBoundaryKey,
        child: Container(
          color: Colors.white, // Solid white background
          child: Stack(
            children: [
              // Background Pattern Layer
              Positioned.fill(
                child: CustomPaint(
                  painter: BackgroundPatternPainter(
                    icons: _getBackgroundIcons(),
                    spacing:
                        screenWidth * 0.15, // Increased spacing between icons
                  ),
                ),
              ),

              // Content Layer with slightly transparent background
              Container(
                color: Colors.white.withOpacity(0.85), // Adjusted opacity
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row for splash image and headline
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                localizations.yearlyStatsShareProgressMyYear,
                                style: TextStyle(
                                  fontFamily: 'RobotoMono',
                                  fontSize: screenWidth * 0.08,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.05),
                          Image.asset(
                            'assets/splash.png',
                            width: screenWidth * 0.1,
                            height: screenWidth * 0.1,
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Statistics with Icons
                      _buildStatItem(
                        context,
                        AppLocalizations.of(context)!
                            .labelCoffeeBrewed, // Just the label without colon
                        '${widget.data.totalLiters.toStringAsFixed(1)}${AppLocalizations.of(context)!.litersUnit}',
                        Icons.local_cafe,
                        screenWidth,
                      ),
                      _buildStatItem(
                        context,
                        AppLocalizations.of(context)!
                            .labelTastedBeansBy, // This returns a simple String
                        AppLocalizations.of(context)!.formattedRoasterCount(
                          widget.data.distinctRoasterCount.toInt(),
                        ),
                        Coffeico.bean,
                        screenWidth,
                      ),
                      _buildStatItem(
                        context,
                        AppLocalizations.of(context)!
                            .labelDiscoveredCoffeeFrom, // This returns a simple String
                        AppLocalizations.of(context)!.formattedCountryCount(
                          widget.data.distinctOriginCount.toInt(),
                        ),
                        Icons.public,
                        screenWidth,
                      ),
                      _buildStatItem(
                        context,
                        AppLocalizations.of(context)!
                            .labelUsedBrewingMethods, // This returns a simple String
                        AppLocalizations.of(context)!
                            .formattedBrewingMethodCount(
                          widget.data.distinctMethods.length,
                        ),
                        Icons.science,
                        screenWidth,
                      ),
                      // Brewing Methods Icons
                      SizedBox(height: screenHeight * 0.02),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: widget.data.distinctMethods.map((methodId) {
                          return Builder(
                            builder: (context) => Container(
                              height: 24,
                              width: 24,
                              child: IconTheme(
                                data: const IconThemeData(
                                  size: 24,
                                  color: Colors.black,
                                ),
                                child: getIconByBrewingMethod(methodId),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Divider before Top-3 Recipes
                      Divider(thickness: 1, color: Colors.grey.shade300),

                      SizedBox(height: screenHeight * 0.02),

                      // Top-3 Recipes
                      Text(
                        localizations.yearlyStatsShareProgressTop3Recipes,
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      ...widget.data.top3Recipes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final recipe = entry.value;

                        // Define trophy colors
                        Color trophyColor;
                        switch (index) {
                          case 0:
                            trophyColor = const Color(0xFFFFD700); // Gold
                            break;
                          case 1:
                            trophyColor = const Color(0xFFC0C0C0); // Silver
                            break;
                          case 2:
                            trophyColor = const Color(0xFFCD7F32); // Bronze
                            break;
                          default:
                            trophyColor = Colors.grey;
                        }

                        return Padding(
                          padding: EdgeInsets.only(
                            left: screenWidth * 0.03,
                            bottom: screenHeight * 0.01,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.emoji_events,
                                  color: trophyColor, size: 24),
                              SizedBox(width: screenWidth * 0.02),
                              Expanded(
                                child: Text(
                                  recipe.name,
                                  style: TextStyle(
                                    fontFamily: 'RobotoMono',
                                    fontSize: screenWidth * 0.045,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      SizedBox(height: screenHeight * 0.03),

                      // Divider before Top-3 Roasters
                      Divider(thickness: 1, color: Colors.grey.shade300),

                      SizedBox(height: screenHeight * 0.02),

                      // Top-3 Roasters with Logos
                      _buildRoasterSection(screenWidth, screenHeight),
                    ],
                  ),
                ),
              )
            ],
          ),
        ));
  }

  // --------------------------------------
  List<IconData> _getBackgroundIcons() {
    return [
      Coffeico.aeropress,
      Coffeico.chemex,
      Coffeico.clever_dripper,
      Coffeico.french_press,
      Coffeico.hario_v60,
      Coffeico.kalita_wave,
      Coffeico.origami,
      Coffeico.wilfa_svart,
      Coffeico.portafilter,
      Coffeico.coffee_maker,
      Coffeico.hario_switch,
    ];
  }

  Widget _buildStatItem(BuildContext context, String label, String value,
      dynamic icon, double screenWidth) {
    Widget leadingIcon;

    if (icon is IconData) {
      leadingIcon = Icon(
        icon,
        size: 24,
        color: Colors.black54,
      );
    } else if (icon is Widget) {
      leadingIcon = icon;
    } else {
      leadingIcon = const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.02),
      child: Row(
        children: [
          leadingIcon,
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: screenWidth * 0.05,
                      color: Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoasterSection(double screenWidth, double screenHeight) {
    if (widget.data.top3Roasters.isEmpty) {
      return const SizedBox.shrink(); // Hide section completely if no roasters
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.yearlyStatsShareProgressTop3Roasters,
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: screenHeight * 0.015),
        FutureBuilder<Map<String, Map<String, String?>>>(
          future: _roasterLogosFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final roasterLogos = snapshot.data!;
            return Column(
              children: widget.data.top3Roasters.map((roaster) {
                final logoUrls = roasterLogos[roaster]!;
                final originalLogoUrl = logoUrls['original'];
                final mirrorLogoUrl = logoUrls['mirror'];

                return Padding(
                  padding: EdgeInsets.only(
                    left: screenWidth * 0.02, // Reduced padding
                    bottom: screenHeight * 0.01, // Reduced padding
                  ),
                  child: Row(
                    children: [
                      // Display the roaster logo using CachedNetworkImage with fallback
                      originalLogoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: originalLogoUrl,
                              placeholder: (context, url) =>
                                  const Icon(Coffeico.bag_with_bean, size: 30),
                              errorWidget: (context, url, error) {
                                // Attempt to load mirror URL if original fails
                                if (mirrorLogoUrl != null &&
                                    mirrorLogoUrl.isNotEmpty) {
                                  return CachedNetworkImage(
                                    imageUrl: mirrorLogoUrl,
                                    placeholder: (context, url) => const Icon(
                                        Coffeico.bag_with_bean,
                                        size: 30),
                                    errorWidget: (context, url, error) {
                                      // Increment the counter as both URLs failed
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        setState(() {
                                          _loadedLogos++;
                                        });
                                        _checkAllLogosHandled();
                                      });
                                      return const Icon(
                                        Coffeico.bag_with_bean,
                                        size: 30,
                                        color: Colors.grey,
                                      );
                                    },
                                    imageBuilder: (context, imageProvider) {
                                      // Increment the counter when mirror logo loads
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        setState(() {
                                          _loadedLogos++;
                                        });
                                        _checkAllLogosHandled();
                                      });
                                      return Image(
                                        image: imageProvider,
                                        width: 30,
                                        height: 30,
                                        fit: BoxFit.contain,
                                      );
                                    },
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  );
                                }
                                // Increment the counter if original URL fails and no mirror
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  setState(() {
                                    _loadedLogos++;
                                  });
                                  _checkAllLogosHandled();
                                });
                                return const Icon(
                                  Coffeico.bag_with_bean,
                                  size: 30,
                                  color: Colors.grey,
                                );
                              },
                              imageBuilder: (context, imageProvider) {
                                // Increment the counter when original logo loads
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  setState(() {
                                    _loadedLogos++;
                                  });
                                  _checkAllLogosHandled();
                                });
                                return Image(
                                  image: imageProvider,
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.contain,
                                );
                              },
                              width: 30, // Reduced size
                              height: 30, // Reduced size
                              fit: BoxFit.contain,
                            )
                          : const Icon(
                              Coffeico.bag_with_bean,
                              size: 30, // Reduced size
                              color: Colors.grey,
                            ),
                      SizedBox(width: screenWidth * 0.015), // Reduced spacing
                      Expanded(
                        child: Text(
                          roaster,
                          style: TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: screenWidth * 0.04, // Reduced font size
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  final List<IconData> icons;
  final double spacing;

  BackgroundPatternPainter({
    required this.icons,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final iconPainter = TextPainter(textDirection: TextDirection.ltr);

    double y = -spacing / 2;
    while (y < size.height + spacing) {
      double x = -spacing / 2;
      while (x < size.width + spacing) {
        final iconIndex = ((x + y) / spacing).floor() % icons.length;
        final icon = icons[iconIndex];
        // Removed null check as icons list should not contain nulls

        iconPainter.text = TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: 40,
            fontFamily: icon.fontFamily, // Using the icon's actual font family
            package: icon.fontPackage, // Adding the font package parameter
            color: Colors.black.withOpacity(0.2),
          ),
        );
        iconPainter.layout();

        final xPos = x - (iconPainter.width / 2);
        final yPos = y - (iconPainter.height / 2);

        iconPainter.paint(
          canvas,
          Offset(xPos, yPos),
        );
        x += spacing;
      }
      y += spacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// First, create a Hearts Animation Widget
class FloatingHeart extends StatefulWidget {
  final double startX;
  final double startY;
  final VoidCallback onCompleted; // Added callback parameter

  const FloatingHeart({
    Key? key,
    required this.startX,
    required this.startY,
    required this.onCompleted, // Initialize the callback
  }) : super(key: key);

  @override
  State<FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<FloatingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Scale animation
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Opacity animation
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Position animation with random horizontal movement
    final random = Random();
    final endX =
        random.nextDouble() * 100 - 50; // Random value between -50 and 50
    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(endX, -150), // Move upward with random horizontal drift
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) {
      if (mounted) {
        widget.onCompleted(); // Use the callback to remove the overlay
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.startX,
      top: widget.startY,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: _positionAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 30,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Create a Shaking Love Button Widget
class _ShakingLoveButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final double? fontSize;

  const _ShakingLoveButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.fontSize,
  }) : super(key: key);

  @override
  State<_ShakingLoveButton> createState() => _ShakingLoveButtonState();
}

class _ShakingLoveButtonState extends State<_ShakingLoveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );
  }

  void _showHearts(BuildContext context, Offset position) {
    final overlay = Overlay.of(context);
    final random = Random();

    for (var i = 0; i < 5; i++) {
      OverlayEntry? entry; // Declare the OverlayEntry
      entry = OverlayEntry(
        builder: (context) => FloatingHeart(
          startX: position.dx - 15 + random.nextDouble() * 30,
          startY: position.dy - 15 + random.nextDouble() * 30,
          onCompleted: () {
            entry?.remove(); // Remove the OverlayEntry when done
          },
        ),
      );
      overlay.insert(entry);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Removed unused localizations variable

    return AbsorbPointer(
      absorbing: false,
      child: Semantics(
        button: true,
        label: widget.text,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: sin(_shakeController.value * pi * 8) *
                    _shakeAnimation.value,
                child: child,
              );
            },
            child: ElevatedButton(
              onPressed: () {
                // Get the button's position
                final RenderBox box = context.findRenderObject() as RenderBox;
                final position = box.localToGlobal(
                  Offset(box.size.width / 2, box.size.height / 2),
                );

                // Trigger animations
                _shakeController
                    .forward()
                    .then((_) => _shakeController.reset());
                _showHearts(context, position);

                // Call the original onPressed
                widget.onPressed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 24, color: Colors.red),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        fontSize: widget.fontSize ?? 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
