import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:auto_route/auto_route.dart';
import 'package:auto_size_text_plus/auto_size_text_plus.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:coffee_timer/utils/icon_utils.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../app_router.gr.dart';

class _CountedItem {
  final String id;
  final int count;
  final DateTime lastUsed;

  const _CountedItem(this.id, this.count, this.lastUsed);
}

class _PeakDayInfo {
  final List<DateTime> days; // sorted desc
  final int count;
  final double? liters;

  const _PeakDayInfo({
    required this.days,
    required this.count,
    this.liters,
  });
}

class _StoryData {
  final int userBrews;
  final double userLiters;
  final int globalBrews;
  final double globalLiters;
  final int? topPct;
  final String? topMethodName;
  final List<_CountedItem> topMethods;
  final Map<String, String> methodIdToName;
  final List<RecipeModel> topRecipes;
  final _PeakDayInfo? peakDay;
  final Duration? totalBrewTime;
  final double roasterCoverage;
  final int uniqueRoasters;
  final List<String> topRoastersSafe;
  final double originCoverage;
  final int uniqueOriginNotes;
  final List<String> topOriginsSafe;
  final bool hasLocalBeans;
  final bool hasAnyBeans;
  final int globalRoasters;
  final int globalCountries;

  _StoryData({
    required this.userBrews,
    required this.userLiters,
    required this.globalBrews,
    required this.globalLiters,
    required this.topPct,
    required this.topMethodName,
    required this.topMethods,
    required this.methodIdToName,
    required this.topRecipes,
    required this.peakDay,
    required this.totalBrewTime,
    required this.roasterCoverage,
    required this.uniqueRoasters,
    required this.topRoastersSafe,
    required this.originCoverage,
    required this.uniqueOriginNotes,
    required this.topOriginsSafe,
    required this.hasLocalBeans,
    required this.hasAnyBeans,
    required this.globalRoasters,
    required this.globalCountries,
  });
}

class _StoryConfig {
  final Duration duration;
  final VoidCallback onStart;
  final bool allowTapAdvance;
  final bool allowTapForward;
  final bool autoStartProgress;
  final bool waitForInteractive;
  final Widget Function(BuildContext context, _StoryData data) builder;

  const _StoryConfig({
    required this.duration,
    required this.builder,
    this.onStart = _defaultStart,
    this.allowTapAdvance = true,
    this.allowTapForward = true,
    this.autoStartProgress = true,
    this.waitForInteractive = false,
  });

  static void _defaultStart() {}
}

@RoutePage()
class YearlyStatsStory25Screen extends StatefulWidget {
  const YearlyStatsStory25Screen({super.key});

  @override
  State<YearlyStatsStory25Screen> createState() =>
      _YearlyStatsStory25ScreenState();
}

class _YearlyStatsStory25ScreenState extends State<YearlyStatsStory25Screen>
    with TickerProviderStateMixin {
  static const double _storyTitleFontSize = 78.0;
  static const TextStyle _storyTitleStyle = TextStyle(
    fontSize: _storyTitleFontSize,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  static const double _emojiTileSize = 56.0;
  static const double _emojiTilePad = _emojiTileSize / 2;
  static const double _emojiOverlayOpacity = 0.65;
  static const List<double> _emojiRotationsDeg = [-12.0, -4.0, 6.0, 12.0, -8.0];
  static const String _trackingSchema = 'service';
  static const String _trackingTable = 'year_story_clicks';
  static const String _trackingSource = 'year_story_25';
  static const String _trackingInstallIdKey = 'year_story_install_id';

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  double? _resolvedTitleFontSize;

  late Future<_StoryData> _futureStoryData;
  late AnimationController _progressController;
  bool _globalCountSnap = false;
  Timer? _globalCountTimer;
  int _globalCountValue = 0;
  int _globalCountStepIndex = 0;
  static const List<int> _globalCountSteps = [
    0,
    8000,
    17000,
    27000,
    39000,
    52000,
    66000,
    79000,
    90000,
    97000,
    100000,
  ];
  static const List<Duration> _globalCountStepDurations = [
    Duration(milliseconds: 240),
    Duration(milliseconds: 240),
    Duration(milliseconds: 240),
    Duration(milliseconds: 240),
    Duration(milliseconds: 240),
    Duration(milliseconds: 240),
    Duration(milliseconds: 240),
    Duration(milliseconds: 240),
    Duration(milliseconds: 240),
    Duration(milliseconds: 240),
  ];

  late AnimationController _slide2FadeController;
  late Animation<double> _slide2FadeAnimation;

  late AnimationController _slide2Row4Controller;
  late AnimationController _slide2Row5Controller;
  late Animation<double> _slide2Row4Fade;
  late Animation<double> _slide2Row5Fade;
  bool _slide2Row2Started = false;
  Timer? _slide2Row5DelayTimer;
  bool _slide2Row5Pending = false;

  late AnimationController _slide3Row2Controller;
  late AnimationController _slide3Row3Controller;
  late Animation<double> _slide3Row2Fade;
  late Animation<double> _slide3Row3Fade;
  Timer? _slide3Row2DelayTimer;
  Timer? _slide3Row3DelayTimer;

  Timer? _slide4Timer;
  bool _showSlide4Details = false;
  bool _isPaused = false;
  bool _holdPaused = false;
  bool _pendingAutoProgress = false;
  bool _showTopBadge = false;
  int _slide4ScratchSeed = 0;
  bool _slide4Scratched = false;
  bool _autoPausedForRecipe = false;
  late AnimationController _slide4ScratchFadeController;
  late Animation<double> _slide4ScratchFade;
  final GlobalKey _slide4ScratchKey = GlobalKey();

  late AnimationController _slide5MethodsHeaderController;
  late AnimationController _slide5RecipesHeaderController;
  late Animation<double> _slide5MethodsHeaderFade;
  late Animation<double> _slide5RecipesHeaderFade;
  late List<AnimationController> _slide5MethodControllers;
  late List<AnimationController> _slide5RecipeControllers;
  late List<Animation<double>> _slide5MethodFades;
  late List<Animation<double>> _slide5RecipeFades;
  Timer? _slide5MethodDelayTimer;
  Timer? _slide5RecipeDelayTimer;
  int _slide5MethodIndex = 0;
  int _slide5RecipeIndex = 0;
  int _slide5MethodCount = 0;
  int _slide5RecipeCount = 0;
  bool _slide5IgnorePause = false;
  Timer? _slide5RecipesHeaderDelayTimer;
  final GlobalKey _slide5RecipesKey = GlobalKey();
  late List<AnimationController> _slide6RoasterControllers;
  late List<Animation<double>> _slide6RoasterFades;
  Timer? _slide6RoasterDelayTimer;
  int _slide6RoasterIndex = 0;
  int _slide6RoasterCount = 0;
  late AnimationController _slide7SubtitleController;
  late Animation<double> _slide7SubtitleFade;
  late List<AnimationController> _slide7OriginControllers;
  late List<Animation<double>> _slide7OriginFades;
  Timer? _slide7SubtitleDelayTimer;
  Timer? _slide7OriginDelayTimer;
  int _slide7OriginIndex = 0;
  int _slide7OriginCount = 0;
  bool _slide7IgnorePause = false;

  final TextEditingController _wishController = TextEditingController();
  final FocusNode _wishFocusNode = FocusNode();
  bool _isSendingWish = false;
  bool _wishSent = false;
  bool _wishSkipped = false;
  String? _wishError;
  String? _receivedWish;
  final GlobalKey _shareButtonKey = GlobalKey();
  final GlobalKey _postcardContinueKey = GlobalKey();
  final GlobalKey _ctaGiftKey = GlobalKey();
  final GlobalKey _ctaDonateKey = GlobalKey();
  final GlobalKey _ctaInstagramKey = GlobalKey();
  OverlayEntry? _shareOverlay;
  String? _cachedInstallId;
  String? _cachedAppVersion;
  bool _trackedOpen = false;
  bool _trackedLastSlide = false;

  String _appBarTitle = '';
  int _slide1Index = 0;
  int _slide2Index = 1;
  int _slide3Index = -1;
  int _slide4Index = -1;
  int _slide5Index = -1;
  int _slide6Index = -1;
  int _slide7Index = -1;
  int _postcardIndex = -1;
  int _ctaIndex = -1;
  final GlobalKey _postcardInputKey = GlobalKey();
  final GlobalKey _postcardButtonsKey = GlobalKey();

  int _currentStoryIndex = 0;
  List<_StoryConfig> _stories = [];

  @override
  void initState() {
    super.initState();

    _futureStoryData = _fetchStoryData();

    _progressController = AnimationController(
      vsync: this,
      duration: Duration.zero,
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _goToNextStory();
        }
      });

    _globalCountValue = 0;

    _slide2FadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            _currentStoryIndex == _slide2Index) {
          setState(() => _slide2Row2Started = true);
          _startGlobalCountTicker();
        }
      });
    _slide2FadeAnimation = CurvedAnimation(
      parent: _slide2FadeController,
      curve: Curves.easeIn,
    );

    _slide2Row4Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            _currentStoryIndex == _slide2Index) {
          _scheduleSlide2Row5Delay();
        }
      });
    _slide2Row4Fade = CurvedAnimation(
      parent: _slide2Row4Controller,
      curve: Curves.easeIn,
    );

    _slide2Row5Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            _currentStoryIndex == _slide2Index) {
          _startProgressIfAllowed();
        }
      });
    _slide2Row5Fade = CurvedAnimation(
      parent: _slide2Row5Controller,
      curve: Curves.easeIn,
    );

    _slide3Row2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            _currentStoryIndex == _slide3Index) {
          if (_showTopBadge) {
            _scheduleSlide3Row3Delay();
          } else {
            _startProgressIfAllowed();
          }
        }
      });
    _slide3Row2Fade = CurvedAnimation(
      parent: _slide3Row2Controller,
      curve: Curves.easeIn,
    );

    _slide3Row3Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            _currentStoryIndex == _slide3Index) {
          _startProgressIfAllowed();
        }
      });
    _slide3Row3Fade = CurvedAnimation(
      parent: _slide3Row3Controller,
      curve: Curves.easeIn,
    );

    _slide4ScratchFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slide4ScratchFade =
        CurvedAnimation(parent: _slide4ScratchFadeController, curve: Curves.easeOut);

    _slide5MethodsHeaderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            _currentStoryIndex == _slide5Index) {
          _scheduleSlide5MethodDelay();
        }
      });
    _slide5MethodsHeaderFade = CurvedAnimation(
      parent: _slide5MethodsHeaderController,
      curve: Curves.easeIn,
    );

    _slide5RecipesHeaderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            _currentStoryIndex == _slide5Index) {
          _scheduleSlide5RecipeDelay();
        }
      });
    _slide5RecipesHeaderFade = CurvedAnimation(
      parent: _slide5RecipesHeaderController,
      curve: Curves.easeIn,
    );

    _slide5MethodControllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _slide5MethodFades = _slide5MethodControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeIn))
        .toList();
    for (final controller in _slide5MethodControllers) {
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            _currentStoryIndex == _slide5Index) {
          _slide5MethodIndex++;
          if (_slide5MethodIndex >= _slide5MethodCount) {
            _startSlide5RecipesHeader();
          } else {
            _scheduleSlide5MethodDelay();
          }
        }
      });
    }

    _slide5RecipeControllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _slide5RecipeFades = _slide5RecipeControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeIn))
        .toList();
    for (final controller in _slide5RecipeControllers) {
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            _currentStoryIndex == _slide5Index) {
          _slide5RecipeIndex++;
          if (_slide5RecipeIndex >= _slide5RecipeCount) {
            _startProgressIfAllowed();
          } else {
            _scheduleSlide5RecipeDelay();
          }
        }
      });
    }

    _slide6RoasterControllers = List.generate(
      6,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _slide6RoasterFades = _slide6RoasterControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeIn))
        .toList();
    for (final controller in _slide6RoasterControllers) {
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            _currentStoryIndex == _slide6Index) {
          _slide6RoasterIndex++;
          if (_slide6RoasterIndex >= _slide6RoasterCount) {
            _startProgressIfAllowed();
          } else {
            _scheduleSlide6RoasterDelay();
          }
        }
      });
    }

    _slide7SubtitleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            _currentStoryIndex == _slide7Index) {
          _scheduleSlide7OriginDelay();
        }
      });
    _slide7SubtitleFade = CurvedAnimation(
      parent: _slide7SubtitleController,
      curve: Curves.easeIn,
    );

    _slide7OriginControllers = List.generate(
      11,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _slide7OriginFades = _slide7OriginControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeIn))
        .toList();
    for (final controller in _slide7OriginControllers) {
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            _currentStoryIndex == _slide7Index) {
          _slide7OriginIndex++;
          if (_slide7OriginIndex >= _slide7OriginCount) {
            _startProgressIfAllowed();
          } else {
            _scheduleSlide7OriginDelay();
          }
        }
      });
    }

    _futureStoryData.then((data) {
      if (!mounted) return;
      if (_stories.isEmpty) {
        setState(() {
          _stories = _buildStories(data);
          _currentStoryIndex = 0;
          _appBarTitle = _useSimpleRecapTitle(data)
              ? _l10n.yearlyStats25AppBarTitleSimple
              : _l10n.yearlyStats25AppBarTitle;
        });
        _startStory(_currentStoryIndex);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appBarTitle.isEmpty) {
      _appBarTitle = _l10n.yearlyStats25AppBarTitle;
    }
  }

  @override
  void dispose() {
    _wishFocusNode.dispose();
    _shareOverlay?.remove();
    _shareOverlay = null;
    _progressController.dispose();
    _slide2FadeController.dispose();
    _slide2Row4Controller.dispose();
    _slide2Row5Controller.dispose();
    _slide3Row2Controller.dispose();
    _slide3Row3Controller.dispose();
    _slide4ScratchFadeController.dispose();
    _slide5MethodsHeaderController.dispose();
    _slide5RecipesHeaderController.dispose();
    for (final controller in _slide5MethodControllers) {
      controller.dispose();
    }
    for (final controller in _slide5RecipeControllers) {
      controller.dispose();
    }
    for (final controller in _slide6RoasterControllers) {
      controller.dispose();
    }
    _slide7SubtitleController.dispose();
    for (final controller in _slide7OriginControllers) {
      controller.dispose();
    }
    _slide2Row5DelayTimer?.cancel();
    _slide3Row2DelayTimer?.cancel();
    _slide3Row3DelayTimer?.cancel();
    _globalCountTimer?.cancel();
    _slide4Timer?.cancel();
    _slide5MethodDelayTimer?.cancel();
    _slide5RecipeDelayTimer?.cancel();
    _slide5RecipesHeaderDelayTimer?.cancel();
    _slide6RoasterDelayTimer?.cancel();
    _slide7SubtitleDelayTimer?.cancel();
    _slide7OriginDelayTimer?.cancel();
    _wishController.dispose();
    super.dispose();
  }

  // ------------------------
  // Story data
  // ------------------------
  Future<_StoryData> _fetchStoryData() async {
    final userStatProvider =
        Provider.of<UserStatProvider>(context, listen: false);
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    final db = Provider.of<DatabaseProvider>(context, listen: false);

    final start = DateTime(2025, 1, 1);
    final end = DateTime(2026, 1, 1);

    final statsAll = await userStatProvider.fetchAllUserStats();
    final stats = statsAll
        .where((s) =>
            !s.isDeleted &&
            !s.createdAt.isBefore(start) &&
            s.createdAt.isBefore(end))
        .toList();

    final userBrews = stats.length;
    final userLiters = stats.fold<double>(
      0.0,
      (sum, s) => sum + (s.waterAmount < 0 ? 0.0 : s.waterAmount) / 1000.0,
    );
    AppLogger.debug(
        'YearlyStats25: userBrews=$userBrews, userLiters=${userLiters.toStringAsFixed(2)}');

    final globalLiters =
        await db.fetchGlobalBrewedCoffeeAmountAggregated(start, end);
    final globalBrews = await db.fetchGlobalBrewsCountAggregated(start, end);
    AppLogger.debug(
        'YearlyStats25: globalBrews=$globalBrews, globalLiters=${globalLiters.toStringAsFixed(2)}');

    // Methods
    final methodCounts = <String, _CountedItem>{};
    for (final s in stats) {
      final id = s.brewingMethodId;
      final prev = methodCounts[id];
      final last = prev == null || s.createdAt.isAfter(prev.lastUsed)
          ? s.createdAt
          : prev.lastUsed;
      methodCounts[id] = _CountedItem(id, (prev?.count ?? 0) + 1, last);
    }

    final topMethods = methodCounts.values.toList()
      ..sort((a, b) {
        final c = b.count.compareTo(a.count);
        return c != 0 ? c : b.lastUsed.compareTo(a.lastUsed);
      });

    final methodIdToName = <String, String>{};
    for (final item in topMethods.take(3)) {
      try {
        final name = await recipeProvider.getBrewingMethodName(item.id);
        methodIdToName[item.id] = name;
      } catch (_) {
        // ignore
      }
    }

    final topMethodName = topMethods.isNotEmpty
        ? (methodIdToName[topMethods.first.id] ?? topMethods.first.id)
        : null;
    AppLogger.debug(
        'YearlyStats25: topMethods=${topMethods.take(3).map((m) => m.id).join(', ')}');

    // Top recipes
    final topRecipeIds =
        await userStatProvider.fetchTopRecipeIdsForPeriod(start, end);
    final topRecipesNullable =
        await Future.wait(topRecipeIds.map(recipeProvider.getRecipeById));
    final topRecipes = topRecipesNullable.whereType<RecipeModel>().toList();
    AppLogger.debug(
        'YearlyStats25: topRecipes=${topRecipes.map((r) => r.name).join(', ')}');

    // Peak day
    _PeakDayInfo? peakDay;
    if (stats.isNotEmpty) {
      final byDay = <DateTime, int>{};
      final litersByDay = <DateTime, double>{};
      for (final s in stats) {
        final day =
            DateTime(s.createdAt.year, s.createdAt.month, s.createdAt.day);
        byDay[day] = (byDay[day] ?? 0) + 1;
        litersByDay[day] = (litersByDay[day] ?? 0) +
            (s.waterAmount < 0 ? 0.0 : s.waterAmount) / 1000.0;
      }
      final sorted = byDay.entries.toList()
        ..sort((a, b) {
          final c = b.value.compareTo(a.value);
          return c != 0 ? c : b.key.compareTo(a.key);
        });
      final peakCount = sorted.first.value;
      final topDays = sorted
          .where((e) => e.value == peakCount)
          .map((e) => e.key)
          .toList()
        ..sort((a, b) => b.compareTo(a));
      peakDay = _PeakDayInfo(
        days: topDays,
        count: peakCount,
        liters: litersByDay[topDays.first],
      );
      AppLogger.debug(
          'YearlyStats25: peakDayCount=$peakCount, peakDays=${topDays.length}');
    }

    // Total brew time (approx from recipe brew time)
    Duration? totalBrewTime;
    if (stats.isNotEmpty) {
      final recipeCounts = <String, int>{};
      for (final s in stats) {
        if (s.recipeId.isEmpty) continue;
        recipeCounts[s.recipeId] = (recipeCounts[s.recipeId] ?? 0) + 1;
      }
      var totalSeconds = 0;
      for (final entry in recipeCounts.entries) {
        final recipe = await recipeProvider.getRecipeById(entry.key);
        if (recipe == null) continue;
        totalSeconds += recipe.brewTime.inSeconds * entry.value;
      }
      totalBrewTime = Duration(seconds: totalSeconds);
    }
    AppLogger.debug(
        'YearlyStats25: totalBrewTimeSeconds=${totalBrewTime?.inSeconds ?? 0}');

    // Beans + roasters/origins (2025 brews or beans list fallback)
    final allBeans = await coffeeBeansProvider.fetchAllCoffeeBeans();
    final activeBeans = allBeans.where((b) => !b.isDeleted).toList();
    final beansByUuid = <String, CoffeeBeansModel>{
      for (final b in activeBeans) b.beansUuid: b,
    };

    double roasterCoverage = 0.0;
    int uniqueRoasters = 0;
    List<String> topRoastersSafe = [];
    double originCoverage = 0.0;
    int uniqueOriginNotes = 0;

    final roasterCountsFromBeans = <String, int>{};
    final originCountsFromBeans = <String, int>{};
    for (final bean in activeBeans) {
      if (!_isBeanAddedInYear(bean, 2025)) continue;
      final roaster = bean.roaster.trim();
      if (roaster.isNotEmpty) {
        roasterCountsFromBeans[roaster] =
            (roasterCountsFromBeans[roaster] ?? 0) + 1;
      }
      final origin = bean.origin.trim();
      if (origin.isNotEmpty) {
        originCountsFromBeans[origin] =
            (originCountsFromBeans[origin] ?? 0) + 1;
      }
    }

    final roasterCountsFromBrews = <String, int>{};
    final originCountsFromBrews = <String, int>{};
    var roasterBrews = 0;
    var originBrews = 0;

    for (final s in stats) {
      final uuid = s.coffeeBeansUuid;
      if (uuid == null || uuid.isEmpty) continue;
      final bean = beansByUuid[uuid];
      if (bean == null) continue;

      final roaster = bean.roaster.trim();
      if (roaster.isNotEmpty) {
        roasterBrews += 1;
        roasterCountsFromBrews[roaster] =
            (roasterCountsFromBrews[roaster] ?? 0) + 1;
      }

      final origin = bean.origin.trim();
      if (origin.isNotEmpty) {
        originBrews += 1;
        originCountsFromBrews[origin] =
            (originCountsFromBrews[origin] ?? 0) + 1;
      }
    }

    final roasterCounts = roasterCountsFromBeans;
    final originCounts = originCountsFromBeans;

    final hasLocalBeans = roasterCounts.isNotEmpty || originCounts.isNotEmpty;
    final hasAnyBeans = activeBeans.isNotEmpty;
    uniqueRoasters = roasterCounts.length;
    uniqueOriginNotes = originCounts.length;

    roasterCoverage = userBrews == 0 ? 0.0 : roasterBrews / userBrews;
    originCoverage = userBrews == 0 ? 0.0 : originBrews / userBrews;

    final roasterSorted = roasterCounts.keys.toList()
      ..sort((a, b) => roasterCounts[b]!.compareTo(roasterCounts[a]!));
    final originSorted = originCounts.keys.toList()
      ..sort((a, b) => originCounts[b]!.compareTo(originCounts[a]!));
    topRoastersSafe = roasterSorted.where(_isSafeDisplay).toList();
    final topOriginsSafe = originSorted.where(_isSafeDisplay).toList();
    AppLogger.debug(
        'YearlyStats25: hasLocalBeans=$hasLocalBeans, uniqueRoasters=$uniqueRoasters, uniqueOrigins=$uniqueOriginNotes');

    // Ranking
    final rank = await db.fetchUserYearlyPercentile(2025);
    final topPct =
        (rank?.topPct != null && rank!.topPct! <= 40) ? rank.topPct : null;
    AppLogger.debug(
        'YearlyStats25: rankTopPct=${rank?.topPct}, activeUsers=${rank?.activeUsers}');

    return _StoryData(
      userBrews: userBrews,
      userLiters: userLiters,
      globalBrews: globalBrews,
      globalLiters: globalLiters,
      topPct: topPct,
      topMethodName: topMethodName,
      topMethods: topMethods,
      methodIdToName: methodIdToName,
      topRecipes: topRecipes,
      peakDay: peakDay,
      totalBrewTime: totalBrewTime,
      roasterCoverage: roasterCoverage,
      uniqueRoasters: uniqueRoasters,
      topRoastersSafe: topRoastersSafe,
      originCoverage: originCoverage,
      uniqueOriginNotes: uniqueOriginNotes,
      topOriginsSafe: topOriginsSafe,
      hasLocalBeans: hasLocalBeans,
      hasAnyBeans: hasAnyBeans,
      globalRoasters: 2386,
      globalCountries: 57,
    );
  }

  List<_StoryConfig> _buildStories(_StoryData data) {
    final stories = <_StoryConfig>[];
    var index = 0;
    final includeBrewSlides = data.userBrews >= 3;
    final useSimpleTitle = _useSimpleRecapTitle(data);

    stories.add(
      _StoryConfig(
        duration: const Duration(seconds: 4),
        builder: (context, data) {
          const progressBarAreaHeight = 20.0; // 4px bar + 8px vertical padding
          final topReserved = kToolbarHeight +
              MediaQuery.of(context).padding.top +
              progressBarAreaHeight;
          final l10n = AppLocalizations.of(context)!;
          return _slideSurface(
            emoji: '☕️',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth * 0.86;
                final primaryTitle = useSimpleTitle
                    ? l10n.yearlyStats25AppBarTitleSimple
                    : l10n.yearlyStats25Slide1Title;
                final displayPrimary = primaryTitle;
                final sizePrimary = _computeTitleFontSizeForText(
                  primaryTitle,
                  availableWidth,
                  2,
                  context,
                  minSize: 12,
                );
                final sizeReference = _computeTitleFontSizeForText(
                  l10n.yearlyStats25Slide1Title,
                  availableWidth,
                  2,
                  context,
                  minSize: 12,
                );
                final computedSize = math.min(sizePrimary, sizeReference);
                if (_resolvedTitleFontSize == null ||
                    (_resolvedTitleFontSize! - computedSize).abs() >= 0.5) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() => _resolvedTitleFontSize = computedSize);
                  });
                }
                return Transform.translate(
                  offset: Offset(0, -topReserved / 2),
                  child: FractionallySizedBox(
                    widthFactor: 0.86,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          displayPrimary,
                          maxLines: 2,
                          minFontSize: 12,
                          stepGranularity: 0.5,
                          overflow: TextOverflow.visible,
                          softWrap: true,
                          textAlign: TextAlign.left,
                          style: _storyTitleStyle.copyWith(
                            fontSize: computedSize,
                          ),
                        ),
                        if (!useSimpleTitle) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _subtitleText(
                            l10n.yearlyStats25Slide1Subtitle,
                            maxLines: 2,
                            fontSize: computedSize / 2,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
    _slide1Index = index++;

    stories.add(
      _StoryConfig(
        duration: const Duration(seconds: 6),
        waitForInteractive: true,
        onStart: () {
          _stopGlobalCountTicker(reset: true);
          _slide2Row2Started = false;
          _slide2Row5Pending = false;
          _slide2Row5DelayTimer?.cancel();
          _slide2FadeController.reset();
          _slide2Row4Controller.reset();
          _slide2Row5Controller.reset();
          _slide2FadeController.forward();
        },
        builder: (context, data) => _globalCommunitySlide(data),
      ),
    );
    _slide2Index = index++;

    if (includeBrewSlides) {
      stories.add(
        _StoryConfig(
        duration: const Duration(seconds: 7),
        waitForInteractive: true,
        onStart: () {
          _slide3Row2Controller.reset();
          _slide3Row3Controller.reset();
          _showTopBadge = false;
          _slide3Row2DelayTimer?.cancel();
          _slide3Row3DelayTimer?.cancel();
        },
        builder: (context, data) {
          final l10n = AppLocalizations.of(context)!;
          final currentValue = data.userLiters;
          final topBadge = data.topPct != null && data.topPct! <= 40
              ? l10n.yearlyStats25Slide3TopBadge(data.topPct!)
              : null;
          _showTopBadge = topBadge != null;
          final brewsText = _formatBrews(data.userBrews);
          final litersText = _formatLiters(currentValue);
          final titleLine = l10n.yearlyStats25Slide3Title;
          final subtitleLine =
              l10n.yearlyStats25Slide3Subtitle(brewsText, litersText);
          final topPctLabel = data.topPct != null ? '${data.topPct}%' : '';

          return _slideSurface(
            emoji: '📈',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _titleText(titleLine),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _slide3Row2Fade,
                  child: _subtitleHighlightedText(
                    subtitleLine,
                    [brewsText, litersText],
                    maxLines: null,
                  ),
                ),
                if (topBadge != null) ...[
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _slide3Row3Fade,
                    child: _subtitleHighlightedText(
                      topBadge,
                      [topPctLabel],
                      maxLines: null,
                    ),
                  ),
                ],
              ],
            ),
            );
          },
        ),
      );
      _slide3Index = index++;

      stories.add(
        _StoryConfig(
        duration: const Duration(seconds: 7),
        onStart: () {
          if (_slide4Scratched) {
            _showSlide4Details = true;
            _slide4ScratchFadeController.value = 1.0;
          } else {
            _showSlide4Details = false;
            _slide4ScratchSeed++;
            _slide4ScratchFadeController.value = 0.0;
          }
          _slide4Timer?.cancel();
        },
        autoStartProgress: false,
        builder: (context, data) {
          final l10n = AppLocalizations.of(context)!;
          final showPeak = data.userBrews >= 10 && data.peakDay != null;
          void handleReveal() {
            setState(() {
              _showSlide4Details = true;
              _slide4Scratched = true;
            });
            _slide4ScratchFadeController.forward(from: 0.0);
            if (!_isPaused) {
              _progressController.forward(from: 0.0);
            }
          }
          if (showPeak) {
            final peak = data.peakDay!;
            final localeTag = Localizations.localeOf(context).toLanguageTag();
            final dateFmt = DateFormat.MMMd(localeTag);
            if (peak.days.length == 1) {
              return _slideSurface(
                emoji: '⏱',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleText(
                      l10n.yearlyStats25Slide4TitleSingle),
                  const SizedBox(height: 12),
                    const SizedBox(height: 16),
                    _scratchRevealBox(
                      containerKey: _slide4ScratchKey,
                      scratchKey: ValueKey(
                        'slide4-${_slide4ScratchSeed}-single',
                      ),
                      child: _slide4DetailsSinglePeak(peak, dateFmt),
                      onReveal: handleReveal,
                      hideLabel: _showSlide4Details,
                      overlayOpacity: 1 - _slide4ScratchFade.value,
                    ),
                  ],
                ),
              );
            }
            final mostRecent = dateFmt.format(peak.days.first);
            final litersValue =
                peak.liters != null ? _formatLiters(peak.liters!) : null;
            return _slideSurface(
              emoji: '⏱',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleText(
                      l10n.yearlyStats25Slide4TitleMulti),
                  const SizedBox(height: 12),
                  const SizedBox(height: 16),
                  _scratchRevealBox(
                    containerKey: _slide4ScratchKey,
                    scratchKey: ValueKey(
                      'slide4-${_slide4ScratchSeed}-multi',
                    ),
                    child:
                        _slide4DetailsMultiPeak(mostRecent, peak.count, litersValue),
                    onReveal: handleReveal,
                    hideLabel: _showSlide4Details,
                    overlayOpacity: 1 - _slide4ScratchFade.value,
                  ),
                ],
              ),
            );
          }

          final brewTime = data.totalBrewTime;
          final timeLabel = _formatBrewTime(brewTime, l10n);
          return _slideSurface(
            emoji: '⏱',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _titleText(l10n.yearlyStats25Slide4TitleBrewTime),
                const SizedBox(height: 12),
                const SizedBox(height: 16),
                _scratchRevealBox(
                  containerKey: _slide4ScratchKey,
                  scratchKey: ValueKey(
                    'slide4-${_slide4ScratchSeed}-time',
                  ),
                  child: _slide4DetailsBrewTime(timeLabel),
                  onReveal: handleReveal,
                  hideLabel: _showSlide4Details,
                  overlayOpacity: 1 - _slide4ScratchFade.value,
                ),
              ],
            ),
          );
        },
        ),
      );
      _slide4Index = index++;

      stories.add(
        _StoryConfig(
        duration: const Duration(seconds: 8),
        waitForInteractive: true,
        onStart: () => _prepareSlide5Animations(data),
        builder: (context, data) => _methodsAndRecipesSlide(data),
        ),
      );
      _slide5Index = index++;
    } else {
      _slide3Index = -1;
      _slide4Index = -1;
      _slide5Index = -1;
    }

    if (data.hasLocalBeans) {
      stories.add(
        _StoryConfig(
          duration: const Duration(seconds: 7),
          waitForInteractive: true,
          onStart: () => _prepareSlide6Animations(data),
          builder: (context, data) => _roastersSlide(data),
        ),
      );
      _slide6Index = index++;
      stories.add(
        _StoryConfig(
          duration: const Duration(seconds: 7),
          waitForInteractive: true,
          onStart: () => _prepareSlide7Animations(data),
          builder: (context, data) => _originsSlide(data),
        ),
      );
      _slide7Index = index++;
    } else {
      _slide6Index = -1;
      _slide7Index = -1;
      stories.add(
        _StoryConfig(
          duration: const Duration(days: 1),
          allowTapAdvance: true,
          allowTapForward: false,
          autoStartProgress: false,
          builder: (context, data) => _globalBeansFallbackSlide(data),
        ),
      );
      index++;
    }

    stories.add(
      _StoryConfig(
        duration: const Duration(days: 1),
        allowTapAdvance: true,
        allowTapForward: false,
        autoStartProgress: false,
        builder: (context, data) => _postcardSlide(data),
      ),
    );
    _postcardIndex = index++;

    stories.add(
      _StoryConfig(
        duration: const Duration(days: 1),
        allowTapAdvance: true,
        allowTapForward: false,
        autoStartProgress: false,
        builder: (context, data) => _ctaSlide(data),
      ),
    );
    _ctaIndex = index++;

    return stories;
  }

  // ------------------------
  // Story controls
  // ------------------------
  void _startStory(int index) {
    if (_stories.isEmpty) return;
    if (index == 0 && !_trackedOpen) {
      _trackedOpen = true;
      unawaited(_trackStoryEvent('open'));
    }
    if (index == _ctaIndex && !_trackedLastSlide) {
      _trackedLastSlide = true;
      unawaited(_trackStoryEvent('last_slide'));
    }
    _slide5IgnorePause = index == _slide5Index && _isPaused;
    if (index != _slide2Index) {
      _stopGlobalCountTicker(reset: false);
      _slide2Row5Pending = false;
      _slide2Row5DelayTimer?.cancel();
    }
    _slide7IgnorePause = index == _slide7Index && _isPaused;
    final story = _stories[index];
    story.onStart();

    _progressController.stop();
    _progressController.reset();
    _progressController.duration = story.duration;
    _pendingAutoProgress = story.autoStartProgress;
    if (story.autoStartProgress) {
      _startProgressIfAllowed();
    }
    if (index == _slide4Index && _showSlide4Details && !_isPaused) {
      _progressController.forward();
    }
  }

  void _startGlobalCountTicker() {
    _stopGlobalCountTicker(reset: true);
    _globalCountTimer?.cancel();
    _globalCountSnap = false;
    _globalCountStepIndex = 0;
    _globalCountValue = _globalCountSteps.first;
    setState(() {});
    _scheduleNextGlobalCountStep();
  }

  void _scheduleNextGlobalCountStep() {
    if (_globalCountStepIndex >= _globalCountSteps.length - 1) {
      if (!_globalCountSnap) {
        setState(() => _globalCountSnap = true);
        if (_currentStoryIndex == _slide2Index &&
            _slide2Row4Controller.status != AnimationStatus.completed) {
          _slide2Row4Controller.forward();
        } else if (_currentStoryIndex != _slide2Index) {
          _startProgressIfAllowed();
        }
      }
      return;
    }
    final duration = _globalCountStepDurations[
        _globalCountStepIndex.clamp(0, _globalCountStepDurations.length - 1)];
    _globalCountTimer = Timer(duration, () {
      _globalCountStepIndex =
          (_globalCountStepIndex + 1).clamp(0, _globalCountSteps.length - 1);
      _globalCountValue = _globalCountSteps[_globalCountStepIndex];
      setState(() {});
      _scheduleNextGlobalCountStep();
    });
  }

  void _stopGlobalCountTicker({required bool reset}) {
    _globalCountTimer?.cancel();
    _globalCountTimer = null;
    if (reset) {
      _globalCountStepIndex = 0;
      _globalCountValue = _globalCountSteps.first;
      _globalCountSnap = false;
    }
  }

  void _resumeGlobalCountTicker() {
    if (_globalCountSnap) return;
    if (_globalCountTimer?.isActive ?? false) return;
    _scheduleNextGlobalCountStep();
  }

  void _scheduleSlide3Row2Delay() {
    if (_slide3Row2Controller.status == AnimationStatus.completed ||
        _slide3Row2Controller.isAnimating) {
      return;
    }
    _slide3Row2DelayTimer?.cancel();
    if (_isPaused) return;
    _slide3Row2DelayTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted || _currentStoryIndex != _slide3Index || _isPaused) return;
      if (_slide3Row2Controller.status != AnimationStatus.completed) {
        _slide3Row2Controller.forward();
      }
    });
  }

  void _scheduleSlide3Row3Delay() {
    if (_slide3Row3Controller.status == AnimationStatus.completed ||
        _slide3Row3Controller.isAnimating) {
      return;
    }
    _slide3Row3DelayTimer?.cancel();
    if (_isPaused) return;
    _slide3Row3DelayTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || _currentStoryIndex != _slide3Index || _isPaused) return;
      if (_slide3Row2Controller.status == AnimationStatus.completed &&
          _slide3Row3Controller.status != AnimationStatus.completed) {
        _slide3Row3Controller.forward();
      }
    });
  }

  void _scheduleSlide2Row5Delay() {
    if (_slide2Row5Controller.status == AnimationStatus.completed ||
        _slide2Row5Controller.isAnimating) {
      _slide2Row5Pending = false;
      return;
    }
    _slide2Row5Pending = true;
    _slide2Row5DelayTimer?.cancel();
    if (_isPaused) {
      return;
    }
    _slide2Row5DelayTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted || _currentStoryIndex != _slide2Index || _isPaused) return;
      if (_slide2Row4Controller.status == AnimationStatus.completed &&
          _slide2Row5Controller.status != AnimationStatus.completed) {
        _slide2Row5Pending = false;
        _slide2Row5Controller.forward();
      }
    });
  }

  void _prepareSlide5Animations(_StoryData data) {
    _slide5MethodCount = math.min(3, data.topMethods.length);
    _slide5RecipeCount = math.min(3, data.topRecipes.length);
    if (_slide5MethodCount == 0) _slide5MethodCount = 1;
    if (_slide5RecipeCount == 0) _slide5RecipeCount = 1;
    _slide5MethodIndex = 0;
    _slide5RecipeIndex = 0;
    _slide5MethodDelayTimer?.cancel();
    _slide5RecipeDelayTimer?.cancel();
    _slide5RecipesHeaderDelayTimer?.cancel();
    _slide5MethodsHeaderController.reset();
    _slide5RecipesHeaderController.reset();
    for (final controller in _slide5MethodControllers) {
      controller.reset();
    }
    for (final controller in _slide5RecipeControllers) {
      controller.reset();
    }
    _slide5MethodsHeaderController.forward();
  }

  void _prepareSlide6Animations(_StoryData data) {
    _slide6RoasterCount = 1;
    _slide6RoasterIndex = 0;
    _slide6RoasterDelayTimer?.cancel();
    for (final controller in _slide6RoasterControllers) {
      controller.reset();
    }
    _startSlide6Roaster();
  }

  void _prepareSlide7Animations(_StoryData data) {
    _slide7IgnorePause = _isPaused;
    final origins = data.topOriginsSafe;
    _slide7OriginCount = math.min(10, origins.length);
    final hasMore = origins.length > 10;
    if (hasMore) _slide7OriginCount += 1;
    if (_slide7OriginCount == 0) _slide7OriginCount = 1;
    _slide7OriginCount =
        _slide7OriginCount.clamp(1, _slide7OriginControllers.length);
    _slide7OriginIndex = 0;
    _slide7SubtitleDelayTimer?.cancel();
    _slide7OriginDelayTimer?.cancel();
    _slide7SubtitleController.reset();
    for (final controller in _slide7OriginControllers) {
      controller.reset();
    }
    _scheduleSlide7SubtitleDelay();
  }

  void _scheduleSlide7SubtitleDelay() {
    _slide7SubtitleDelayTimer?.cancel();
    if (_isPaused && !_slide7IgnorePause) return;
    _slide7SubtitleDelayTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted || _currentStoryIndex != _slide7Index) return;
      if (_isPaused && !_slide7IgnorePause) return;
      _slide7SubtitleController.forward();
    });
  }

  void _scheduleSlide7OriginDelay() {
    if (_slide7OriginIndex >= _slide7OriginCount) {
      _startProgressIfAllowed();
      return;
    }
    final controller = _slide7OriginControllers[_slide7OriginIndex];
    if (controller.status == AnimationStatus.completed ||
        controller.isAnimating) {
      return;
    }
    _slide7OriginDelayTimer?.cancel();
    if (_isPaused && !_slide7IgnorePause) return;
    _slide7OriginDelayTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _currentStoryIndex != _slide7Index) return;
      if (_isPaused && !_slide7IgnorePause) return;
      controller.forward();
    });
  }

  void _resumeSlide7Animations() {
    if (_slide7SubtitleController.status != AnimationStatus.completed) {
      _scheduleSlide7SubtitleDelay();
      return;
    }
    if (_slide7OriginIndex < _slide7OriginCount) {
      final controller = _slide7OriginControllers[_slide7OriginIndex];
      if (controller.status == AnimationStatus.dismissed) {
        _scheduleSlide7OriginDelay();
      } else if (controller.status != AnimationStatus.completed) {
        controller.forward();
      }
    }
  }

  void _startSlide6Roaster() {
    if (_slide6RoasterIndex >= _slide6RoasterCount) {
      _startProgressIfAllowed();
      return;
    }
    if (_isPaused) return;
    final controller = _slide6RoasterControllers[_slide6RoasterIndex];
    if (controller.status == AnimationStatus.dismissed) {
      controller.forward();
    }
  }

  void _scheduleSlide6RoasterDelay() {
    _slide6RoasterDelayTimer?.cancel();
    if (_isPaused) return;
    _slide6RoasterDelayTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _currentStoryIndex != _slide6Index || _isPaused) return;
      _startSlide6Roaster();
    });
  }

  void _resumeSlide6Animations() {
    if (_slide6RoasterIndex >= _slide6RoasterCount) return;
    final controller = _slide6RoasterControllers[_slide6RoasterIndex];
    if (controller.status == AnimationStatus.dismissed) {
      _scheduleSlide6RoasterDelay();
    } else if (controller.status != AnimationStatus.completed) {
      controller.forward();
    }
  }

  void _scheduleSlide5MethodDelay() {
    if (_slide5MethodIndex >= _slide5MethodCount) {
      _startSlide5RecipesHeader();
      return;
    }
    final controller = _slide5MethodControllers[_slide5MethodIndex];
    if (controller.status == AnimationStatus.completed ||
        controller.isAnimating) {
      return;
    }
    _slide5MethodDelayTimer?.cancel();
    if (_isPaused && !_slide5IgnorePause) return;
    _slide5MethodDelayTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _currentStoryIndex != _slide5Index) return;
      if (_isPaused && !_slide5IgnorePause) return;
      controller.forward();
    });
  }

  void _startSlide5RecipesHeader() {
    if (_slide5RecipesHeaderController.status == AnimationStatus.completed ||
        _slide5RecipesHeaderController.isAnimating) {
      return;
    }
    _slide5RecipesHeaderDelayTimer?.cancel();
    if (_isPaused && !_slide5IgnorePause) return;
    _slide5RecipesHeaderDelayTimer =
        Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || _currentStoryIndex != _slide5Index) return;
      if (_isPaused && !_slide5IgnorePause) return;
      _slide5RecipesHeaderController.forward();
    });
  }

  void _scheduleSlide5RecipeDelay() {
    if (_slide5RecipeIndex >= _slide5RecipeCount) {
      _startProgressIfAllowed();
      return;
    }
    final controller = _slide5RecipeControllers[_slide5RecipeIndex];
    if (controller.status == AnimationStatus.completed ||
        controller.isAnimating) {
      return;
    }
    _slide5RecipeDelayTimer?.cancel();
    if (_isPaused && !_slide5IgnorePause) return;
    _slide5RecipeDelayTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _currentStoryIndex != _slide5Index) return;
      if (_isPaused && !_slide5IgnorePause) return;
      controller.forward();
    });
  }

  void _resumeSlide5Animations() {
    if (_slide5MethodsHeaderController.status != AnimationStatus.completed) {
      _slide5MethodsHeaderController.forward();
      return;
    }
    if (_slide5MethodIndex < _slide5MethodCount) {
      final controller = _slide5MethodControllers[_slide5MethodIndex];
      if (controller.status == AnimationStatus.dismissed) {
        _scheduleSlide5MethodDelay();
      } else if (controller.status != AnimationStatus.completed) {
        controller.forward();
      }
      return;
    }
    if (_slide5RecipesHeaderController.status != AnimationStatus.completed) {
      _startSlide5RecipesHeader();
      return;
    }
    if (_slide5RecipeIndex < _slide5RecipeCount) {
      final controller = _slide5RecipeControllers[_slide5RecipeIndex];
      if (controller.status == AnimationStatus.dismissed) {
        _scheduleSlide5RecipeDelay();
      } else if (controller.status != AnimationStatus.completed) {
        controller.forward();
      }
    }
  }

  bool _interactiveFinishedForIndex(int index) {
    if (index == _slide2Index) {
      return _globalCountSnap &&
          _slide2FadeController.status == AnimationStatus.completed &&
          _slide2Row4Controller.status == AnimationStatus.completed &&
          _slide2Row5Controller.status == AnimationStatus.completed;
    }
    if (index == _slide3Index) {
      final badgeNeeded = _showTopBadge;
      final badgeDone = !badgeNeeded ||
          _slide3Row3Controller.status == AnimationStatus.completed;
      return _slide3Row2Controller.status == AnimationStatus.completed &&
          badgeDone;
    }
    if (index == _slide5Index) {
      final methodIndex = (_slide5MethodCount - 1)
          .clamp(0, _slide5MethodControllers.length - 1)
          .toInt();
      final recipeIndex = (_slide5RecipeCount - 1)
          .clamp(0, _slide5RecipeControllers.length - 1)
          .toInt();
      final methodsDone = _slide5MethodCount == 0 ||
          _slide5MethodControllers[methodIndex].status ==
              AnimationStatus.completed;
      final recipesDone = _slide5RecipeCount == 0 ||
          _slide5RecipeControllers[recipeIndex].status ==
              AnimationStatus.completed;
      return _slide5MethodsHeaderController.status ==
              AnimationStatus.completed &&
          methodsDone &&
          _slide5RecipesHeaderController.status ==
              AnimationStatus.completed &&
          recipesDone;
    }
    if (index == _slide6Index) {
      final lastIndex = (_slide6RoasterCount - 1)
          .clamp(0, _slide6RoasterControllers.length - 1)
          .toInt();
      return _slide6RoasterControllers[lastIndex].status ==
          AnimationStatus.completed;
    }
    if (index == _slide7Index) {
      final lastIndex = (_slide7OriginCount - 1)
          .clamp(0, _slide7OriginControllers.length - 1)
          .toInt();
      return _slide7SubtitleController.status ==
              AnimationStatus.completed &&
          _slide7OriginControllers[lastIndex].status ==
              AnimationStatus.completed;
    }
    return true;
  }

  void _startProgressIfAllowed({bool ignorePause = false}) {
    if (_stories.isEmpty) return;
    if (!_pendingAutoProgress) return;
    final story = _stories[_currentStoryIndex];
    if (story.waitForInteractive &&
        !_interactiveFinishedForIndex(_currentStoryIndex)) {
      return;
    }
    if (!ignorePause && _isPaused) {
      return;
    }
    _pendingAutoProgress = false;
    _progressController.forward();
  }

  void _goToNextStory() {
    if (_stories.isEmpty) return;
    if (_currentStoryIndex < _stories.length - 1) {
      setState(() => _currentStoryIndex++);
      _startStory(_currentStoryIndex);
      _playInteractiveElements();
      if (_isPaused) {
        _progressController.stop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goToPreviousStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _startStory(_currentStoryIndex);
      _playInteractiveElements();
      if (_isPaused) {
        _progressController.stop();
      }
    }
  }

  void _pauseAllAnimations() {
    _progressController.stop();
    _stopGlobalCountTicker(reset: false);
    if (_slide2FadeController.isAnimating) _slide2FadeController.stop();
    if (_slide2Row4Controller.isAnimating) _slide2Row4Controller.stop();
    if (_slide2Row5Controller.isAnimating) _slide2Row5Controller.stop();
    if (_slide3Row2Controller.isAnimating) _slide3Row2Controller.stop();
    if (_slide3Row3Controller.isAnimating) _slide3Row3Controller.stop();
    if (_slide5MethodsHeaderController.isAnimating) {
      _slide5MethodsHeaderController.stop();
    }
    if (_slide5RecipesHeaderController.isAnimating) {
      _slide5RecipesHeaderController.stop();
    }
    for (final controller in _slide5MethodControllers) {
      if (controller.isAnimating) controller.stop();
    }
    for (final controller in _slide5RecipeControllers) {
      if (controller.isAnimating) controller.stop();
    }
    for (final controller in _slide6RoasterControllers) {
      if (controller.isAnimating) controller.stop();
    }
    if (_slide7SubtitleController.isAnimating) {
      _slide7SubtitleController.stop();
    }
    for (final controller in _slide7OriginControllers) {
      if (controller.isAnimating) controller.stop();
    }
    _slide2Row5DelayTimer?.cancel();
    _slide3Row2DelayTimer?.cancel();
    _slide3Row3DelayTimer?.cancel();
    _slide4Timer?.cancel();
    _slide5MethodDelayTimer?.cancel();
    _slide5RecipeDelayTimer?.cancel();
    _slide5RecipesHeaderDelayTimer?.cancel();
    _slide6RoasterDelayTimer?.cancel();
    _slide7SubtitleDelayTimer?.cancel();
    _slide7OriginDelayTimer?.cancel();
  }

  void _resumeAllAnimations() {
    if (_stories.isEmpty) return;
    final story = _stories[_currentStoryIndex];
    if (_progressController.value > 0 &&
        _progressController.value < 1 &&
        !_progressController.isAnimating) {
      _progressController.forward();
    } else if (_currentStoryIndex == _slide4Index && _showSlide4Details) {
      _progressController.forward();
    } else if (story.autoStartProgress) {
      _startProgressIfAllowed(ignorePause: true);
    }
    if (_currentStoryIndex == _slide3Index) {
      if (_slide3Row2Controller.status != AnimationStatus.completed) {
        _scheduleSlide3Row2Delay();
      }
      if (_showTopBadge &&
          _slide3Row2Controller.status == AnimationStatus.completed &&
          _slide3Row3Controller.status != AnimationStatus.completed) {
        _scheduleSlide3Row3Delay();
      }
    }
    if (_currentStoryIndex == _slide5Index) {
      _resumeSlide5Animations();
    }
    if (_currentStoryIndex == _slide6Index) {
      _resumeSlide6Animations();
    }
    if (_currentStoryIndex == _slide7Index) {
      _resumeSlide7Animations();
    }
    if (_currentStoryIndex == _slide2Index && !_globalCountSnap) {
      _resumeGlobalCountTicker();
    }
    if (_currentStoryIndex == _slide2Index &&
        _slide2FadeController.status != AnimationStatus.completed) {
      _slide2FadeController.forward();
    }
    if (_currentStoryIndex == _slide2Index &&
        !_slide2Row2Started &&
        _slide2FadeController.status == AnimationStatus.completed) {
      setState(() => _slide2Row2Started = true);
      _startGlobalCountTicker();
    }
    if (_currentStoryIndex == _slide2Index &&
        _slide2Row4Controller.status != AnimationStatus.completed &&
        _globalCountSnap) {
      _slide2Row4Controller.forward();
    }
    if (_currentStoryIndex == _slide2Index &&
        _slide2Row5Controller.status != AnimationStatus.completed &&
        _slide2Row4Controller.status == AnimationStatus.completed) {
      _scheduleSlide2Row5Delay();
    }
  }

  void _playInteractiveElements() {
    if (_currentStoryIndex == _slide2Index && !_globalCountSnap) {
      _resumeGlobalCountTicker();
    }
    if (_currentStoryIndex == _slide2Index &&
        _slide2FadeController.status != AnimationStatus.completed) {
      _slide2FadeController.forward();
    }
    if (_currentStoryIndex == _slide2Index &&
        !_slide2Row2Started &&
        _slide2FadeController.status == AnimationStatus.completed) {
      setState(() => _slide2Row2Started = true);
      _startGlobalCountTicker();
    }
    if (_currentStoryIndex == _slide2Index &&
        _slide2Row4Controller.status != AnimationStatus.completed &&
        _globalCountSnap) {
      _slide2Row4Controller.forward();
    }
    if (_currentStoryIndex == _slide2Index &&
        _slide2Row5Controller.status != AnimationStatus.completed &&
        _slide2Row4Controller.status == AnimationStatus.completed) {
      _scheduleSlide2Row5Delay();
    }
    if (_currentStoryIndex == _slide3Index) {
      if (_slide3Row2Controller.status != AnimationStatus.completed) {
        _scheduleSlide3Row2Delay();
      }
      if (_showTopBadge &&
          _slide3Row2Controller.status == AnimationStatus.completed &&
          _slide3Row3Controller.status != AnimationStatus.completed) {
        _scheduleSlide3Row3Delay();
      }
    }
    if (_currentStoryIndex == _slide5Index) {
      _resumeSlide5Animations();
    }
    if (_currentStoryIndex == _slide6Index) {
      _resumeSlide6Animations();
    }
    if (_currentStoryIndex == _slide7Index) {
      _resumeSlide7Animations();
    }
  }

  void _togglePause() {
    if (_isPaused) {
      _resumeAllAnimations();
    } else {
      _pauseAllAnimations();
    }
    _holdPaused = false;
    setState(() => _isPaused = !_isPaused);
  }

  void _handleHoldPauseStart() {
    if (_isPaused) return;
    _holdPaused = true;
    setState(() => _isPaused = true);
    _pauseAllAnimations();
  }

  void _handleHoldPauseEnd() {
    if (!_holdPaused) return;
    _holdPaused = false;
    setState(() => _isPaused = false);
    _resumeAllAnimations();
    _playInteractiveElements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _appBarTitle,
            maxLines: 1,
            softWrap: false,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _isPaused
                ? _l10n.yearlyStats25AppBarTooltipResume
                : _l10n.yearlyStats25AppBarTooltipPause,
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: _togglePause,
          ),
        ],
      ),
      body: FutureBuilder<_StoryData>(
        future: _futureStoryData,
        builder: (context, snapshot) {
          if (!snapshot.hasData || _stories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final story = _stories[_currentStoryIndex];

          final progressBars = <Widget>[];
          for (var i = 0; i < _stories.length; i++) {
            double value;
            if (i < _currentStoryIndex) {
              value = 1.0;
            } else if (i > _currentStoryIndex) {
              value = 0.0;
            } else {
              value = _progressController.value;
            }

            progressBars.add(
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 4,
                    backgroundColor: Colors.black12,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
              ),
            );
          }

          Widget content = Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(children: progressBars),
              ),
              Expanded(child: story.builder(context, data)),
            ],
          );

          content = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: story.allowTapAdvance
                ? (details) {
                    if (_isTapOnScratchCard(details.globalPosition) ||
                        _isTapOnRecipes(details.globalPosition) ||
                        _isTapOnPostcardInput(details.globalPosition) ||
                        _isTapOnPostcardButtons(details.globalPosition) ||
                        _isTapOnCtaButtons(details.globalPosition)) {
                      return;
                    }
                    if (_wishFocusNode.hasFocus) {
                      FocusScope.of(context).unfocus();
                      return;
                    }
                    if (_isPostcardVisible()) {
                      FocusScope.of(context).unfocus();
                    }
                    if (_currentStoryIndex == 0 && story.allowTapForward) {
                      _goToNextStory();
                      return;
                    }
                    final width = MediaQuery.of(context).size.width;
                    final dx = details.localPosition.dx;
                    if (dx < width * 0.2) {
                      _goToPreviousStory();
                    } else if (dx > width * 0.8 && story.allowTapForward) {
                      _goToNextStory();
                    }
                  }
                : null,
            onLongPressStart: (_) => _handleHoldPauseStart(),
            onLongPressEnd: (_) => _handleHoldPauseEnd(),
            onLongPressCancel: _handleHoldPauseEnd,
            child: content,
          );

          return content;
        },
      ),
    );
  }

  bool _isTapOnScratchCard(Offset globalPosition) {
    final context = _slide4ScratchKey.currentContext;
    if (context == null) return false;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    if (!renderObject.attached) return false;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    final rect = (topLeft & renderObject.size).inflate(6);
    return rect.contains(globalPosition);
  }

  bool _isTapOnRecipes(Offset globalPosition) {
    if (_currentStoryIndex != _slide5Index) return false;
    final context = _slide5RecipesKey.currentContext;
    if (context == null) return false;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    if (!renderObject.attached) return false;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    final rect = (topLeft & renderObject.size).inflate(6);
    return rect.contains(globalPosition);
  }

  bool _isTapOnPostcardInput(Offset globalPosition) {
    final context = _postcardInputKey.currentContext;
    if (context == null) return false;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    if (!renderObject.attached) return false;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    final rect = (topLeft & renderObject.size).inflate(6);
    return rect.contains(globalPosition);
  }

  bool _isTapOnPostcardButtons(Offset globalPosition) {
    return _isTapOnKey(_postcardButtonsKey, globalPosition) ||
        _isTapOnKey(_postcardContinueKey, globalPosition);
  }

  bool _isTapOnCtaButtons(Offset globalPosition) {
    if (_stories.isEmpty || _currentStoryIndex != _stories.length - 1) {
      return false;
    }
    return _isTapOnKey(_ctaGiftKey, globalPosition) ||
        _isTapOnKey(_ctaDonateKey, globalPosition) ||
        _isTapOnKey(_ctaInstagramKey, globalPosition) ||
        _isTapOnKey(_shareButtonKey, globalPosition);
  }

  bool _isPostcardVisible() {
    return _postcardInputKey.currentContext != null ||
        _postcardButtonsKey.currentContext != null ||
        _postcardContinueKey.currentContext != null;
  }

  bool _isTapOnKey(GlobalKey key, Offset globalPosition) {
    final context = key.currentContext;
    if (context == null) return false;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    if (!renderObject.attached) return false;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    final rect = (topLeft & renderObject.size).inflate(6);
    return rect.contains(globalPosition);
  }

  // ------------------------
  // Slides
  // ------------------------
  Widget _simpleSlide({
    String? title,
    String? subtitle,
    String? footer,
    required String emoji,
    List<InlineSpan>? titleSpans,
  }) {
    return _slideSurface(
      emoji: emoji,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            _titleText(title!),
          if (titleSpans != null)
            _titleRich(titleSpans),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            _subtitleText(subtitle!),
          ],
          if (footer != null) ...[
            const SizedBox(height: 16),
            _subtitleText(footer!),
          ],
        ],
      ),
    );
  }

  Widget _globalCommunitySlide(_StoryData data) {
    final countText = _globalCountSnap
        ? '100.000+'
        : _formatBrews(_globalCountValue);
    final l10n = _l10n;
    final litersText = _formatLiters(data.globalLiters);

    return _slideSurface(
      emoji: '🌍',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeTransition(
            opacity: _slide2FadeAnimation,
            child: _subtitleText(l10n.yearlyStats25Slide2Intro),
          ),
          const SizedBox(height: 8),
          if (_slide2Row2Started)
            _titleText(l10n.yearlyStats25Slide2Count(countText)),
          const SizedBox(height: 12),
          FadeTransition(
            opacity: _slide2Row4Fade,
            child: _subtitleHighlightedText(
              l10n.yearlyStats25Slide2Liters(litersText),
              [litersText],
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 12),
          FadeTransition(
            opacity: _slide2Row5Fade,
            child: _subtitleText(
              l10n.yearlyStats25Slide2Cambridge,
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodsAndRecipesSlide(_StoryData data) {
    final topMethods = data.topMethods.take(3).toList();
    final topRecipes = data.topRecipes.take(3).toList();
    final l10n = _l10n;

    return _slideSurface(
      emoji: '🧪',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleText(l10n.yearlyStats25Slide5Title),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _slide5MethodsHeaderFade,
            child: _subtitleText(l10n.yearlyStats25Slide5MethodsHeader,
                maxLines: 1),
          ),
          const SizedBox(height: 8),
          if (topMethods.isEmpty)
            FadeTransition(
              opacity: _slide5MethodFades.first,
              child: _subtitleText(l10n.yearlyStats25Slide5NoMethods),
            )
          else
            ...topMethods.asMap().entries.map((entry) {
              final index = entry.key;
              final method = entry.value;
              final opacity = _slide5MethodFades[
                  index.clamp(0, _slide5MethodFades.length - 1)];
              return FadeTransition(
                opacity: opacity,
                child: _methodRow(method, data),
              );
            }),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: _slide5RecipesHeaderFade,
            child:
                _subtitleText(l10n.yearlyStats25Slide5RecipesHeader, maxLines: 1),
          ),
          const SizedBox(height: 8),
          if (topRecipes.isEmpty)
            FadeTransition(
              opacity: _slide5RecipeFades.first,
              child: _subtitleText(l10n.yearlyStats25Slide5NoRecipes),
            )
          else
            Container(
              key: _slide5RecipesKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: topRecipes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final recipe = entry.value;
                  final opacity = _slide5RecipeFades[
                      index.clamp(0, _slide5RecipeFades.length - 1)];
                  return FadeTransition(
                    opacity: opacity,
                    child: _recipeRow(recipe),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _methodRow(_CountedItem method, _StoryData data) {
    final name = data.methodIdToName[method.id] ?? method.id;
    final l10n = _l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          getIconByBrewingMethod(method.id),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              l10n.yearlyStats25MethodRow(name, method.count),
              style: _subtitleStyle(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recipeRow(RecipeModel recipe) {
    return InkWell(
      onTap: () => _openRecipeDetail(recipe),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            getIconByBrewingMethod(recipe.brewingMethodId),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                recipe.name,
                style: _subtitleStyle().copyWith(
                  decoration: TextDecoration.underline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roastersSlide(_StoryData data) {
    final l10n = _l10n;
    return _slideSurface(
      emoji: '🔥',
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleText(
            l10n.yearlyStats25Slide6Title(
              _formatCount(data.uniqueRoasters),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final listStyle = _subtitleStyle();
                final listText = _buildRoasterListText(
                  data.topRoastersSafe,
                  listStyle,
                  constraints.maxWidth,
                  math.max(0.0, constraints.maxHeight - 8),
                  Directionality.of(context),
                  MediaQuery.textScaleFactorOf(context),
                  l10n.yearlyStats25Slide6NoRoasters,
                  l10n.yearlyStats25Others,
                );
                return Align(
                  alignment: Alignment.topLeft,
                  child: FadeTransition(
                    opacity: _slide6RoasterFades.first,
                    child: Text(
                      listText,
                      style: listStyle,
                      textAlign: TextAlign.left,
                      maxLines: null,
                      overflow: TextOverflow.clip,
                      softWrap: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _originsSlide(_StoryData data) {
    final origins = data.topOriginsSafe;
    final originsToShow = origins.take(10).toList();
    final showOthers = origins.length > 10;
    final l10n = _l10n;
    return _slideSurface(
      emoji: '🌱',
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleText(l10n.yearlyStats25Slide7Title, maxLines: 3),
          const SizedBox(height: 12),
          FadeTransition(
            opacity: _slide7SubtitleFade,
            child: _subtitleText(
              l10n.yearlyStats25Slide7Subtitle(
                _formatCount(data.uniqueOriginNotes),
              ),
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < originsToShow.length; i++) ...[
                  FadeTransition(
                    opacity: _slide7OriginFades[i],
                    child: _subtitleText(originsToShow[i], maxLines: 1),
                  ),
                  const SizedBox(height: 6),
                ],
                if (showOthers)
                  FadeTransition(
                    opacity: _slide7OriginFades[
                        originsToShow.length.clamp(0, _slide7OriginFades.length - 1)],
                    child: _subtitleText(l10n.yearlyStats25Others, maxLines: 1),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _globalBeansFallbackSlide(_StoryData data) {
    final l10n = _l10n;
    final prompt = data.hasAnyBeans
        ? l10n.yearlyStats25FallbackPromptHasBeans
        : l10n.yearlyStats25FallbackPromptNoBeans;
    final actionLabel =
        data.hasAnyBeans
            ? l10n.yearlyStats25FallbackActionHasBeans
            : l10n.yearlyStats25FallbackActionNoBeans;
    return _slideSurface(
      emoji: '🗺️',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleText = l10n.yearlyStats25FallbackTitle(
            data.globalCountries,
            data.globalRoasters,
          );
          final computedSize =
              (_resolvedTitleFontSize ?? _storyTitleFontSize) / 2;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _applyWidowControl(titleText),
                maxLines: null,
                overflow: TextOverflow.visible,
                softWrap: true,
                textAlign: TextAlign.left,
                style: _storyTitleStyle.copyWith(
                  fontSize: computedSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _subtitleText(prompt, maxLines: null),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: _buildActionButton(
                  actionLabel,
                  () => context.router.push(NewBeansRoute()),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child:
                    _buildActionButton(l10n.yearlyStats25ContinueButton, _goToNextStory),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _postcardSlide(_StoryData data) {
    if (_wishSent && _receivedWish == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadIncomingWish();
      });
    }

    final l10n = _l10n;
    return _slideSurface(
      emoji: '💌',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleText(l10n.yearlyStats25PostcardTitle),
          const SizedBox(height: 8),
          _subtitleText(l10n.yearlyStats25PostcardSubtitle),
          const SizedBox(height: 16),
          if (!_wishSent)
            Container(
              key: _postcardInputKey,
              child: TextField(
                controller: _wishController,
                focusNode: _wishFocusNode,
                maxLength: 160,
                maxLines: 3,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: l10n.yearlyStats25PostcardHint,
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          if (_wishError != null) ...[
            const SizedBox(height: 8),
            Text(
              _wishError!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.left,
            ),
          ],
          const SizedBox(height: 12),
          if (!_wishSent)
            Container(
              key: _postcardButtonsKey,
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActionButton(
                    _isSendingWish
                        ? l10n.yearlyStats25PostcardSending
                        : l10n.yearlyStats25PostcardSend,
                    _isSendingWish ? null : _sendWish,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildActionButton(l10n.yearlyStats25PostcardSkip, () {
                    setState(() {
                      _wishSkipped = true;
                      _wishError = null;
                    });
                    _goToNextStory();
                  }),
                ],
              ),
            ),
          if (_wishSent) ...[
            const SizedBox(height: 16),
            Text(
              l10n.yearlyStats25PostcardReceivedTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildWishCard(),
            const SizedBox(height: AppSpacing.sm),
            Container(
              key: _postcardContinueKey,
              width: double.infinity,
              child: _buildActionButton(
                l10n.yearlyStats25ContinueButton,
                _goToNextStory,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWishCard() {
    final text = _receivedWish ?? _l10n.yearlyStats25PostcardHint;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _ctaSlide(_StoryData data) {
    final l10n = _l10n;
    final bulletStyle = _subtitleStyle();
    final showShare = !kIsWeb && data.userBrews >= 3 && data.hasAnyBeans;
    return _slideSurface(
      emoji: '🎁',
      child: SizedBox.expand(
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              _titleText(l10n.yearlyStats25CtaTitle),
              const SizedBox(height: 12),
              _subtitleText(l10n.yearlyStats25CtaSubtitle),
              const SizedBox(height: AppSpacing.lg),
              _bulletLine(
                [
                  TextSpan(text: l10n.yearlyStats25CtaExplorePrefix),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: _inlineActionButton(
                      l10n.yearlyStats25CtaGiftBox,
                      () => context.router.push(const GiftBoxListRoute()),
                      key: _ctaGiftKey,
                    ),
                  ),
                ],
                style: bulletStyle,
              ),
              const SizedBox(height: 12),
              _bulletLine(
                [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: _inlineActionButton(
                      l10n.yearlyStats25CtaDonate,
                      () => context.router.push(const DonationRoute()),
                      key: _ctaDonateKey,
                    ),
                  ),
                  TextSpan(text: l10n.yearlyStats25CtaDonateSuffix),
                ],
                style: bulletStyle,
              ),
              const SizedBox(height: 12),
              _bulletLine(
                [
                  TextSpan(text: l10n.yearlyStats25CtaFollowPrefix),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: _inlineActionButton(
                      l10n.yearlyStats25CtaInstagram,
                      _openInstagram,
                      key: _ctaInstagramKey,
                    ),
                  ),
                ],
                style: bulletStyle,
              ),
              if (showShare) ...[
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(
                    l10n.yearlyStats25CtaShareButton,
                    () => _shareRecap(data),
                    key: _shareButtonKey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.yearlyStats25CtaShareHint,
                  textAlign: TextAlign.left,
                  style: _subtitleStyle(
                    color: Colors.black54,
                    fontSize: bulletStyle.fontSize != null
                        ? bulletStyle.fontSize! * 0.8
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _bulletLine(
    List<InlineSpan> spans, {
    required TextStyle style,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: style),
        Expanded(
          child: RichText(
            textAlign: TextAlign.left,
            text: TextSpan(style: style, children: spans),
          ),
        ),
      ],
    );
  }

  Widget _inlineActionButton(
    String label,
    VoidCallback onPressed, {
    Key? key,
  }) {
    final textStyle = _subtitleStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        textStyle: textStyle,
      ),
      onPressed: onPressed,
      key: key,
      child: Text(label),
    );
  }

  Future<void> _openInstagram() async {
    final uri = Uri.parse('https://www.instagram.com/timercoffeeapp');
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      AppLogger.warning('YearlyStats25: failed to open Instagram');
    }
  }

  Widget _buildActionButton(
    String label,
    VoidCallback? onPressed, {
    Key? key,
  }) {
    return SizedBox(
      key: key,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.primary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _scratchRevealBox({
    required Widget child,
    required VoidCallback onReveal,
    Key? containerKey,
    Key? scratchKey,
    bool hideLabel = false,
    double overlayOpacity = 1.0,
  }) {
    return SizedBox(
      key: containerKey,
      height: 140,
      width: double.infinity,
      child: _ScratchReveal(
        key: scratchKey,
        label: _l10n.yearlyStats25Slide4ScratchLabel,
        onReveal: onReveal,
        borderRadius: BorderRadius.circular(AppRadius.card),
        backgroundColor: Theme.of(context).colorScheme.surface,
        labelStyle: _subtitleStyle(color: Colors.black54),
        overlayOpacity: overlayOpacity,
        scratchRadius: 22,
        cellSize: 20,
        revealThreshold: 0.3,
        showLabel: !hideLabel,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: child,
        ),
      ),
    );
  }

  List<String> _buildNumberUnitHighlights(String text, String number) {
    if (number.isEmpty) return const [];
    final highlights = <String>[number];
    final index = text.indexOf(number);
    if (index == -1) return highlights;

    final afterIndex = index + number.length;
    var i = afterIndex;
    while (i < text.length && (text[i] == ' ' || text[i] == '\u00A0')) {
      i++;
    }
    if (i < text.length) {
      final match =
          RegExp(r'^\p{L}+', unicode: true).firstMatch(text.substring(i));
      if (match != null) {
        final unit = match.group(0)!;
        if (unit.isNotEmpty && unit.length <= 12) {
          highlights.add(unit);
          return highlights;
        }
      }
    }

    var j = index - 1;
    while (j >= 0 && (text[j] == ' ' || text[j] == '\u00A0')) {
      j--;
    }
    if (j >= 0) {
      var end = j + 1;
      var start = j;
      while (start >= 0 &&
          RegExp(r'\p{L}', unicode: true).hasMatch(text[start])) {
        start--;
      }
      start++;
      if (start < end) {
        final unit = text.substring(start, end);
        if (unit.isNotEmpty && unit.length <= 12) {
          highlights.add(unit);
        }
      }
    }
    return highlights;
  }

  Widget _slide4DetailsSinglePeak(_PeakDayInfo peak, DateFormat dateFmt) {
    final l10n = _l10n;
    final dateText = dateFmt.format(peak.days.first);
    final brewsLabel = l10n.yearlyStats25BrewsCount(peak.count);
    final litersValue =
        peak.liters != null ? _formatLiters(peak.liters!) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _subtitleHighlightedText(
          l10n.yearlyStats25Slide4PeakSingle(
            dateText,
            brewsLabel,
          ),
          [dateText, brewsLabel],
          color: Colors.black,
        ),
        if (litersValue != null) ...[
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final litersLine =
                  l10n.yearlyStats25Slide4PeakLiters(litersValue);
              return _subtitleHighlightedText(
                litersLine,
                _buildNumberUnitHighlights(litersLine, litersValue),
                color: Colors.black,
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _slide4DetailsMultiPeak(
    String mostRecent,
    int count,
    String? litersValue,
  ) {
    final l10n = _l10n;
    final brewsLabel = l10n.yearlyStats25BrewsCount(count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _subtitleHighlightedText(
          l10n.yearlyStats25Slide4PeakMostRecent(mostRecent, brewsLabel),
          [mostRecent, brewsLabel],
          color: Colors.black,
        ),
        if (litersValue != null) ...[
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final litersLine =
                  l10n.yearlyStats25Slide4PeakLiters(litersValue);
              return _subtitleHighlightedText(
                litersLine,
                _buildNumberUnitHighlights(litersLine, litersValue),
                color: Colors.black,
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _slide4DetailsBrewTime(String timeLabel) {
    final l10n = _l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _subtitleText(l10n.yearlyStats25Slide4BrewTimeLine(timeLabel),
            color: Colors.black),
        const SizedBox(height: 8),
        _subtitleText(l10n.yearlyStats25Slide4BrewTimeFooter,
            color: Colors.black54),
      ],
    );
  }

  Future<void> _openRecipeDetail(RecipeModel recipe) async {
    if (!mounted) return;
    if (!_isPaused) {
      _pauseAllAnimations();
      setState(() {
        _isPaused = true;
        _autoPausedForRecipe = true;
      });
    } else {
      _autoPausedForRecipe = false;
    }
    await context.router.push(RecipeDetailRoute(
      brewingMethodId: recipe.brewingMethodId,
      recipeId: recipe.id,
    ));
    if (!mounted) return;
    if (_autoPausedForRecipe) {
      _autoPausedForRecipe = false;
      _resumeAllAnimations();
      setState(() => _isPaused = false);
    }
  }

  Future<void> _shareRecap(_StoryData data) async {
    if (kIsWeb) return;
    final overlayState = Overlay.of(context);
    if (overlayState == null) return;
    final GlobalKey repaintBoundaryKey = GlobalKey();
    _shareOverlay?.remove();
    _shareOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Center(
          child: _ShareRecapWidget(
            data: data,
            repaintBoundaryKey: repaintBoundaryKey,
            onReadyToCapture: () async {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await Future.delayed(const Duration(milliseconds: 300));
                await _captureAndShare(repaintBoundaryKey);
                _shareOverlay?.remove();
                _shareOverlay = null;
              });
            },
          ),
        ),
      ),
    );

    overlayState.insert(_shareOverlay!);
  }

  Future<void> _captureAndShare(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Share capture failed');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Share capture failed');
      }
      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file =
          await File('${tempDir.path}/timer_coffee_year_2025.png').create();
      await file.writeAsBytes(pngBytes);

      final xFile = XFile(
        file.path,
        mimeType: 'image/png',
        name: 'timer_coffee_year_2025.png',
      );

      final origin = _getShareOriginRect();
      await Share.shareXFiles(
        [xFile],
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l10n.yearlyStats25ShareError),
          duration: const Duration(seconds: 3),
        ),
      );
      AppLogger.error('YearlyStats25 share error', errorObject: e);
    }
  }

  Rect _getShareOriginRect() {
    RenderBox? buttonBox;
    final buttonContext = _shareButtonKey.currentContext;
    if (buttonContext != null) {
      final renderObject = buttonContext.findRenderObject();
      if (renderObject is RenderBox && renderObject.hasSize) {
        buttonBox = renderObject;
      }
    }

    if (buttonBox != null) {
      final offset = buttonBox.localToGlobal(Offset.zero);
      final size = buttonBox.size;
      if (size.width > 0 && size.height > 0) {
        return offset & size;
      }
    }

    final overlay = Overlay.of(context);
    final overlayObject = overlay?.context.findRenderObject();
    if (overlayObject is RenderBox && overlayObject.hasSize) {
      final offset = overlayObject.localToGlobal(Offset.zero);
      final size = overlayObject.size;
      if (size.width > 0 && size.height > 0) {
        return offset & size;
      }
    }

    final screenSize = MediaQuery.of(context).size;
    return Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
  }

  Future<void> _sendWish() async {
    final l10n = _l10n;
    final text = _wishController.text.trim();
    if (text.length < 2 || text.length > 160) {
      setState(() => _wishError = l10n.yearlyStats25PostcardErrorLength);
      return;
    }

    setState(() {
      _isSendingWish = true;
      _wishError = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final locale = Localizations.localeOf(context).languageCode;
      AppLogger.debug(
        'YearlyStats25: submit wish start len=${text.length}, locale=$locale, user=${AppLogger.sanitizeUserId(user?.id)}, anon=${user?.isAnonymous ?? true}',
      );
      if (user == null) {
        setState(() {
          _wishError = l10n.yearlyStats25PostcardErrorSend;
        });
      } else {
        final response = await supabase.functions.invoke(
          'submit-yearly-wish',
          body: {
            'text': text,
            'locale': locale,
          },
        );

        AppLogger.debug(
          'YearlyStats25: submit-yearly-wish response status=${response.status} data=${AppLogger.sanitize(response.data)}',
        );
        if (response.status != 200 || response.data == null) {
          throw Exception('submit-yearly-wish failed');
        }

        final payload = response.data as Map<String, dynamic>;
        final ok = payload['ok'] == true;
        final status = payload['status'] as String?;
        final rejected = ok && status == 'rejected';
        final approved = ok && status == 'approved';

        if (approved) {
          setState(() {
            _wishSent = true;
            _wishController.clear();
          });
          await _loadIncomingWish();
        } else if (rejected) {
          setState(() {
            _wishError = l10n.yearlyStats25PostcardErrorRejected;
          });
        } else {
          throw Exception('submit-yearly-wish returned invalid payload');
        }
      }
    } catch (_) {
      setState(() {
        _wishError = l10n.yearlyStats25PostcardErrorSend;
      });
    } finally {
      if (mounted) {
        setState(() => _isSendingWish = false);
      }
    }
  }

  Future<void> _loadIncomingWish() async {
    if (_receivedWish != null) return;
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        AppLogger.debug('YearlyStats25: load wish skipped (no user)');
        return;
      }
      final languageCode = Localizations.localeOf(context).languageCode;
      AppLogger.debug(
        'YearlyStats25: load wish start locale=$languageCode user=${AppLogger.sanitizeUserId(user.id)} anon=${user.isAnonymous}',
      );
      final response = await supabase.rpc('pick_yearly_wish', params: {
        'p_user_id': user.id,
        'p_locale': languageCode,
      });
      AppLogger.debug(
        'YearlyStats25: pick_yearly_wish response=${AppLogger.sanitize(response)}',
      );
      if (response is List && response.isNotEmpty && response.first is Map) {
        final row = response.first as Map;
        final text = row['text']?.toString();
        final wishLocale = row['locale']?.toString();
        final localeMatches = wishLocale == languageCode;
        AppLogger.debug(
          'YearlyStats25: wish locale=$wishLocale matches=$localeMatches',
        );
        if (text != null && text.isNotEmpty && localeMatches) {
          if (mounted) {
            setState(() => _receivedWish = text);
          }
        } else {
          AppLogger.debug('YearlyStats25: wish ignored (locale mismatch/empty)');
        }
      }
    } catch (_) {
      // Ignore and use fallback text.
    }
  }

  // ------------------------
  // Tracking
  // ------------------------
  Future<String?> _getOrCreateInstallId() async {
    if (_cachedInstallId != null) return _cachedInstallId;
    try {
      final prefs = await SharedPreferences.getInstance();
      var iid = prefs.getString(_trackingInstallIdKey);
      iid ??= const Uuid().v4();
      await prefs.setString(_trackingInstallIdKey, iid);
      _cachedInstallId = iid;
      return iid;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getAppVersion() async {
    if (_cachedAppVersion != null) return _cachedAppVersion;
    try {
      final info = await PackageInfo.fromPlatform();
      _cachedAppVersion = '${info.version}+${info.buildNumber}';
      return _cachedAppVersion;
    } catch (_) {
      return null;
    }
  }

  String _platformParam() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'other';
  }

  Future<void> _trackStoryEvent(String event) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      AppLogger.debug('YearlyStats25: tracking "$event" skipped (no user)');
      return;
    }
    try {
      final locale = Localizations.localeOf(context).toLanguageTag();
      final installId = await _getOrCreateInstallId();
      final appVersion = await _getAppVersion();
      final payload = <String, dynamic>{
        'src': _trackingSource,
        'event': event,
        'platform': _platformParam(),
        'locale': locale,
        if (appVersion != null) 'app_version': appVersion,
        if (installId != null) 'install_id': installId,
      };
      await supabase
          .schema(_trackingSchema)
          .from(_trackingTable)
          .insert(payload);
      AppLogger.debug('YearlyStats25: tracked "$event"');
    } catch (e) {
      AppLogger.debug('YearlyStats25: tracking "$event" failed',
          errorObject: e);
    }
  }

  // ------------------------
  // Helpers
  // ------------------------
  Widget _slideSurface({required Widget child, required String emoji}) {
    const offWhite = Color(0xFFF7F5F0);
    final overlayColor = offWhite.withOpacity(_emojiOverlayOpacity);
    return Container(
      color: offWhite,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -_emojiTilePad,
            left: -_emojiTilePad,
            right: -_emojiTilePad,
            bottom: -_emojiTilePad,
            child: _emojiTileBackground(emoji),
          ),
          Positioned(
            top: -_emojiTilePad,
            left: -_emojiTilePad,
            right: -_emojiTilePad,
            bottom: -_emojiTilePad,
            child: DecoratedBox(
              decoration: BoxDecoration(color: overlayColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Align(
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiTile(double size, double rotation, String emoji) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Transform.rotate(
          angle: rotation,
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  Widget _emojiGrid(Size size, String emoji) {
    final columns = (size.width / _emojiTileSize).ceil();
    final rows = (size.height / _emojiTileSize).ceil();
    final count = columns * rows;
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 1,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        final rotationDeg =
            _emojiRotationsDeg[index % _emojiRotationsDeg.length];
        final rotation = rotationDeg * math.pi / 180;
        return _buildEmojiTile(_emojiTileSize, rotation, emoji);
      },
    );
  }

  Widget _emojiTileBackground(String emoji) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _emojiGrid(
          Size(constraints.maxWidth, constraints.maxHeight),
          emoji,
        );
      },
    );
  }

  double _computeTitleFontSize(double maxWidth, BuildContext context) {
    final text = AppLocalizations.of(context)!.yearlyStats25Slide1Title;
    const minSize = 22.0;
    final maxSize = _storyTitleFontSize;
    int low = minSize.round();
    int high = maxSize.round();
    int best = low;
    final textDirection = Directionality.of(context);
    final painter = TextPainter(
      textDirection: textDirection,
      maxLines: 2,
    );

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      painter.text = TextSpan(
        text: text,
        style: _storyTitleStyle.copyWith(fontSize: mid.toDouble()),
      );
      painter.layout(maxWidth: maxWidth);
      if (!painter.didExceedMaxLines) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return best.toDouble();
  }

  double _computeTitleFontSizeForText(
    String text,
    double maxWidth,
    int maxLines,
    BuildContext context, {
    double minSize = 18.0,
  }
  ) {
    final maxSize = _resolvedTitleFontSize ?? _storyTitleFontSize;
    int low = minSize.round();
    int high = maxSize.round();
    int best = low;
    final textDirection = Directionality.of(context);
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);
    final painter = TextPainter(
      textDirection: textDirection,
      maxLines: maxLines,
      textScaleFactor: textScaleFactor,
    );

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      painter.text = TextSpan(
        text: text,
        style: _storyTitleStyle.copyWith(fontSize: mid.toDouble()),
      );
      painter.layout(maxWidth: maxWidth);
      if (!painter.didExceedMaxLines) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return best.toDouble();
  }

  Widget _titleText(
    String text, {
    int? maxLines,
    double? fontSize,
  }) {
    final resolvedSize =
        fontSize ?? _resolvedTitleFontSize ?? _storyTitleFontSize;
    final displayText = _applyWidowControl(text);
    return Text(
      displayText,
      textAlign: TextAlign.left,
      maxLines: maxLines,
      overflow: TextOverflow.visible,
      softWrap: true,
      style: _storyTitleStyle.copyWith(fontSize: resolvedSize),
    );
  }

  Widget _titleRich(
    List<InlineSpan> spans, {
    int? maxLines,
    double? fontSize,
  }) {
    final resolvedSize =
        fontSize ?? _resolvedTitleFontSize ?? _storyTitleFontSize;
    return Text.rich(
      TextSpan(
        style: _storyTitleStyle.copyWith(fontSize: resolvedSize),
        children: spans,
      ),
      textAlign: TextAlign.left,
      maxLines: maxLines,
      overflow: TextOverflow.visible,
      softWrap: true,
    );
  }

  Widget _titleHighlightedText(
    String text,
    List<String> highlights, {
    int? maxLines,
    double? fontSize,
  }) {
    final resolvedSize =
        fontSize ?? _resolvedTitleFontSize ?? _storyTitleFontSize;
    final baseStyle = _storyTitleStyle.copyWith(fontSize: resolvedSize);
    final highlightStyle =
        _storyTitleStyle.copyWith(fontSize: resolvedSize, fontWeight: FontWeight.w700);
    return _buildHighlightedText(
      text,
      highlights,
      baseStyle,
      highlightStyle,
      maxLines: maxLines,
    );
  }

  Widget _subtitleText(
    String text, {
    int? maxLines,
    double? fontSize,
    Color color = Colors.black87,
  }) {
    final resolvedSize =
        fontSize ?? (_resolvedTitleFontSize ?? _storyTitleFontSize) / 2;
    final displayText = _applyWidowControl(text);
    final baseStyle = _subtitleStyle(
      color: color,
      fontWeight: FontWeight.w400,
      fontSize: resolvedSize,
    );
    return Text(
      displayText,
      textAlign: TextAlign.left,
      maxLines: maxLines,
      overflow: TextOverflow.visible,
      softWrap: true,
      style: baseStyle,
    );
  }

  TextStyle _subtitleStyle({
    Color color = Colors.black87,
    FontWeight fontWeight = FontWeight.w400,
    double? fontSize,
  }) {
    final resolvedSize =
        fontSize ?? (_resolvedTitleFontSize ?? _storyTitleFontSize) / 2;
    return TextStyle(
      fontSize: resolvedSize,
      color: color,
      fontWeight: fontWeight,
    );
  }

  Widget _subtitleHighlightedText(
    String text,
    List<String> highlights, {
    int? maxLines,
    double? fontSize,
    Color color = Colors.black87,
  }) {
    final resolvedSize =
        fontSize ?? (_resolvedTitleFontSize ?? _storyTitleFontSize) / 2;
    final baseStyle = TextStyle(
      fontSize: resolvedSize,
      color: color,
      fontWeight: FontWeight.w400,
    );
    final highlightStyle = baseStyle.copyWith(fontWeight: FontWeight.w700);
    return _buildHighlightedText(
      text,
      highlights,
      baseStyle,
      highlightStyle,
      maxLines: maxLines,
    );
  }

  Widget _buildHighlightedText(
    String text,
    List<String> highlights,
    TextStyle baseStyle,
    TextStyle highlightStyle, {
    int? maxLines,
  }) {
    final displayText = _applyWidowControl(text);
    if (highlights.isEmpty) {
      return Text(
        displayText,
        textAlign: TextAlign.left,
        maxLines: maxLines,
        overflow: TextOverflow.visible,
        softWrap: true,
        style: baseStyle,
      );
    }

    final spans = <InlineSpan>[];
    var index = 0;
    while (index < displayText.length) {
      int nextIndex = -1;
      int nextLength = 0;
      for (final highlight in highlights) {
        if (highlight.isEmpty) continue;
        final variants = <String>{highlight};
        if (highlight.contains(' ')) {
          variants.add(highlight.replaceAll(' ', '\u00A0'));
        }
        for (final variant in variants) {
          final found = displayText.indexOf(variant, index);
          if (found != -1 && (nextIndex == -1 || found < nextIndex)) {
            nextIndex = found;
            nextLength = variant.length;
          }
        }
      }
      if (nextIndex == -1 || nextLength == 0) {
        spans.add(TextSpan(text: displayText.substring(index), style: baseStyle));
        break;
      }
      if (nextIndex > index) {
        spans.add(TextSpan(
            text: displayText.substring(index, nextIndex), style: baseStyle));
      }
      spans.add(TextSpan(
          text: displayText.substring(nextIndex, nextIndex + nextLength),
          style: highlightStyle));
      index = nextIndex + nextLength;
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      textAlign: TextAlign.left,
      maxLines: maxLines,
      overflow: TextOverflow.visible,
      softWrap: true,
    );
  }

  String _applyWidowControl(String text) {
    final lines = text.split('\n');
    final processed = lines.map((line) {
      final sanitized = line.replaceAll('\u200b', '');
      final trimmedRight = sanitized.trimRight();
      if (trimmedRight.isEmpty) return line;
      var working = trimmedRight;
      final lastSpace = working.lastIndexOf(' ');
      if (lastSpace == -1) {
        return working;
      }
      final lastWord = working.substring(lastSpace + 1);
      final before = working.substring(0, lastSpace);
      return '$before\u00A0$lastWord';
    }).toList();
    return processed.join('\n');
  }

  String _formatLiters(double liters) {
    if (liters < 10) {
      return liters.toStringAsFixed(1).replaceAll(',', '.');
    }
    final rounded = liters.round();
    return NumberFormat.decimalPattern().format(rounded).replaceAll(',', '.');
  }

  String _formatBrews(int brews) {
    if (brews >= 100000) return '100.000+';
    return NumberFormat.decimalPattern().format(brews).replaceAll(',', '.');
  }

  String _formatCount(int value) {
    return NumberFormat.decimalPattern().format(value).replaceAll(',', '.');
  }

  String _buildRoasterListText(
    List<String> roasters,
    TextStyle style,
    double maxWidth,
    double maxHeight,
    TextDirection direction,
    double textScaleFactor,
    String emptyLabel,
    String othersLabel,
  ) {
    if (maxHeight <= 0) return '';
    if (roasters.isEmpty) return emptyLabel;

    bool fits(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaleFactor: textScaleFactor,
      )..layout(maxWidth: maxWidth);
      return painter.height <= maxHeight + 0.5;
    }

    String buildText(List<String> names, {required bool addOthers}) {
      var text = names.join(', ');
      if (addOthers) {
        text = text.isEmpty ? othersLabel : '$text $othersLabel';
      }
      return text;
    }

    final capped = roasters.take(30).toList();
    if (roasters.length <= 30) {
      final fullText = buildText(capped, addOthers: false);
      if (fits(fullText)) {
        return fullText;
      }
    }

    var selected = <String>[];
    for (final roaster in capped) {
      final tentative = [...selected, roaster];
      final remaining = roasters.length - tentative.length;
      final candidate = buildText(tentative, addOthers: remaining > 0);
      if (!fits(candidate)) {
        break;
      }
      selected = tentative;
    }
    final remaining = roasters.length - selected.length;
    return buildText(selected, addOthers: remaining > 0);
  }

  DateTime? _uuidV7ToDateTime(String uuid) {
    final hex = uuid.replaceAll('-', '');
    if (hex.length < 12) return null;
    final tsHex = hex.substring(0, 12);
    final millis = int.tryParse(tsHex, radix: 16);
    if (millis == null) return null;
    final dt = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    if (dt.year < 2010 || dt.year > 2035) return null;
    return dt;
  }

  bool _isBeanAddedInYear(CoffeeBeansModel bean, int year) {
    final dt = _uuidV7ToDateTime(bean.beansUuid);
    if (dt == null) return true;
    return dt.year == year;
  }

  String _formatBrewTime(Duration? duration, AppLocalizations l10n) {
    if (duration == null) return l10n.yearlyStats25BrewTimeMinutes(0);
    final minutes = duration.inMinutes;
    if (minutes < 60) {
      return l10n.yearlyStats25BrewTimeMinutes(minutes);
    }
    final hours = minutes / 60.0;
    if (hours < 10) {
      return l10n.yearlyStats25BrewTimeHours(hours.toStringAsFixed(1));
    }
    return l10n.yearlyStats25BrewTimeHours(hours.round().toString());
  }

  bool _isSafeDisplay(String s) {
    if (s.length < 2 || s.length > 60) return false;
    if (RegExp(r'https?://|www\.').hasMatch(s)) return false;
    if (RegExp(r'\b[^\s@]+@[^\s@]+\.[^\s@]+\b').hasMatch(s)) return false;
    if (RegExp(r'\+?\d[\d\s\-()]{7,}').hasMatch(s)) return false;
    if (RegExp(r'[\x00-\x1F]').hasMatch(s)) return false;
    return true;
  }

  bool _useSimpleRecapTitle(_StoryData data) {
    return data.userBrews < 3 || !data.hasAnyBeans;
  }
}

class _ShareRecapWidget extends StatefulWidget {
  final _StoryData data;
  final GlobalKey repaintBoundaryKey;
  final VoidCallback onReadyToCapture;

  const _ShareRecapWidget({
    required this.data,
    required this.repaintBoundaryKey,
    required this.onReadyToCapture,
  });

  @override
  State<_ShareRecapWidget> createState() => _ShareRecapWidgetState();
}

class _ShareRecapWidgetState extends State<_ShareRecapWidget> {
  static const double _emojiTileSize = 56.0;
  static const double _emojiTilePad = _emojiTileSize / 2;
  static const double _emojiOverlayOpacity = 0.85;
  static const List<double> _emojiRotationsDeg = [
    -12.0,
    -4.0,
    6.0,
    12.0,
    -8.0,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onReadyToCapture();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    double clamp(double value, double min, double max) =>
        value.clamp(min, max).toDouble();

    final titleSize = clamp(width * 0.08, 24, 40);
    final subtitleSize = clamp(width * 0.045, 14, 22);
    final sectionSize = clamp(width * 0.05, 16, 24);

    final brewsText = _formatBrews(widget.data.userBrews);
    final litersText = _formatLiters(widget.data.userLiters);
    final roastersText = _formatCount(widget.data.uniqueRoasters);
    final originsText = _formatCount(widget.data.uniqueOriginNotes);

    final methods = widget.data.topMethods
        .take(3)
        .map((m) => MapEntry(m.id, widget.data.methodIdToName[m.id] ?? m.id))
        .toList();
    final recipes =
        widget.data.topRecipes.take(3).map((r) => r).toList();

    String atName(List<MapEntry<String, String>> items, int index) =>
        index < items.length && items[index].value.isNotEmpty
            ? items[index].value
            : '—';
    String atRecipeName(List<RecipeModel> items, int index) =>
        index < items.length && items[index].name.isNotEmpty
            ? items[index].name
            : '—';
    IconData iconForMethod(String? methodId) =>
        getIconByBrewingMethod(methodId).icon ?? Icons.local_cafe;

    return RepaintBoundary(
      key: widget.repaintBoundaryKey,
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFF7F5F0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -_emojiTilePad,
              left: -_emojiTilePad,
              right: -_emojiTilePad,
              bottom: -_emojiTilePad,
              child: _emojiTileBackground('☕'),
            ),
            Positioned(
              top: -_emojiTilePad,
              left: -_emojiTilePad,
              right: -_emojiTilePad,
              bottom: -_emojiTilePad,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5F0)
                      .withOpacity(_emojiOverlayOpacity),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.08,
                vertical: height * 0.08,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: height * 0.02),
                Text(
                  l10n.yearlyStats25ShareTitle,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: height * 0.02),
                  _shareStatLine(
                    prefix: l10n.yearlyStats25ShareBrewedPrefix,
                    value: brewsText,
                    middle: l10n.yearlyStats25ShareBrewedMiddle,
                    value2: litersText,
                    suffix: l10n.yearlyStats25ShareBrewedSuffix,
                    fontSize: subtitleSize,
                  ),
                  SizedBox(height: height * 0.008),
                  _shareStatLine(
                    prefix: l10n.yearlyStats25ShareRoastersPrefix,
                    value: roastersText,
                    suffix: l10n.yearlyStats25ShareRoastersSuffix,
                    fontSize: subtitleSize,
                  ),
                  SizedBox(height: height * 0.008),
                  _shareStatLine(
                    prefix: l10n.yearlyStats25ShareOriginsPrefix,
                    value: originsText,
                    suffix: l10n.yearlyStats25ShareOriginsSuffix,
                    fontSize: subtitleSize,
                  ),
                  SizedBox(height: height * 0.03),
                  Text(
                    l10n.yearlyStats25ShareMethodsTitle,
                    style: TextStyle(
                      fontSize: sectionSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: height * 0.012),
                  _shareListItem(
                    atName(methods, 0),
                    subtitleSize,
                    iconForMethod(methods.isNotEmpty ? methods[0].key : null),
                  ),
                  _shareListItem(
                    atName(methods, 1),
                    subtitleSize,
                    iconForMethod(methods.length > 1 ? methods[1].key : null),
                  ),
                  _shareListItem(
                    atName(methods, 2),
                    subtitleSize,
                    iconForMethod(methods.length > 2 ? methods[2].key : null),
                  ),
                  SizedBox(height: height * 0.03),
                  Text(
                    l10n.yearlyStats25ShareRecipesTitle,
                    style: TextStyle(
                      fontSize: sectionSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: height * 0.012),
                  _shareListItem(
                    atRecipeName(recipes, 0),
                    subtitleSize,
                    iconForMethod(recipes.isNotEmpty
                        ? recipes[0].brewingMethodId
                        : null),
                  ),
                  _shareListItem(
                    atRecipeName(recipes, 1),
                    subtitleSize,
                    iconForMethod(recipes.length > 1
                        ? recipes[1].brewingMethodId
                        : null),
                  ),
                  _shareListItem(
                    atRecipeName(recipes, 2),
                    subtitleSize,
                    iconForMethod(recipes.length > 2
                        ? recipes[2].brewingMethodId
                        : null),
                  ),
                ],
              ),
            ),
            Positioned(
              right: width * 0.02,
              bottom: height * 0.05,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/app_icon_1024.png',
                    width: clamp(width * 0.08, 22, 40),
                    height: clamp(width * 0.08, 22, 40),
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.yearlyStats25ShareHandle,
                    style: TextStyle(
                      fontSize: clamp(width * 0.035, 12, 18),
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareListItem(String text, double fontSize, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: fontSize + 2, color: Colors.black87),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLiters(double liters) {
    if (liters < 10) {
      return liters.toStringAsFixed(1).replaceAll(',', '.');
    }
    return liters.round().toString().replaceAll(',', '.');
  }

  String _formatBrews(int brews) {
    if (brews >= 100000) return '100.000+';
    return NumberFormat.decimalPattern().format(brews).replaceAll(',', '.');
  }

  String _formatCount(int value) {
    return NumberFormat.decimalPattern().format(value).replaceAll(',', '.');
  }

  Widget _shareStatLine({
    required String prefix,
    required String value,
    String? middle,
    String? value2,
    String? suffix,
    required double fontSize,
  }) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      color: Colors.black87,
    );
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w700);
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: prefix),
          TextSpan(text: value, style: boldStyle),
          if (middle != null) TextSpan(text: middle),
          if (value2 != null) TextSpan(text: value2, style: boldStyle),
          if (suffix != null) TextSpan(text: suffix),
        ],
      ),
      textAlign: TextAlign.left,
    );
  }

  Widget _emojiTileBackground(String emoji) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final columns = (size.width / _emojiTileSize).ceil().clamp(1, 999);
        final rows = (size.height / _emojiTileSize).ceil().clamp(1, 999);
        final count = columns * rows;
        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 1,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
          ),
          itemCount: count,
          itemBuilder: (context, index) {
            final rotationDeg =
                _emojiRotationsDeg[index % _emojiRotationsDeg.length];
            final rotation = rotationDeg * math.pi / 180;
            return SizedBox(
              width: _emojiTileSize,
              height: _emojiTileSize,
              child: Transform.rotate(
                angle: rotation,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(emoji),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ScratchReveal extends StatefulWidget {
  final String label;
  final VoidCallback onReveal;
  final BorderRadius borderRadius;
  final Color overlayColor;
  final Color backgroundColor;
  final TextStyle labelStyle;
  final double revealThreshold;
  final double cellSize;
  final double scratchRadius;
  final Widget child;
  final bool showLabel;
  final double overlayOpacity;

  const _ScratchReveal({
    super.key,
    required this.label,
    required this.onReveal,
    required this.borderRadius,
    this.overlayColor = const Color(0xFFEAE4D9),
    this.backgroundColor = Colors.white,
    this.labelStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.black54,
    ),
    this.revealThreshold = 0.35,
    this.cellSize = 24,
    this.scratchRadius = 18,
    required this.child,
    this.showLabel = true,
    this.overlayOpacity = 1.0,
  });

  @override
  State<_ScratchReveal> createState() => _ScratchRevealState();
}

class _ScratchRevealState extends State<_ScratchReveal>
    with SingleTickerProviderStateMixin {
  final List<Offset> _points = [];
  final Set<int> _scratchedCells = {};
  final List<double> _colWeights = [];
  double _scratchWeightTotal = 0.0;
  double _scratchWeightHit = 0.0;
  Size? _size;
  int _rows = 0;
  int _cols = 0;
  bool _revealTriggered = false;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  void _updateGrid(Size size) {
    if (_size == size) return;
    _size = size;
    _cols = (size.width / widget.cellSize).ceil().clamp(1, 999);
    _rows = (size.height / widget.cellSize).ceil().clamp(1, 999);
    _scratchedCells.clear();
    _points.clear();
    _colWeights
      ..clear()
      ..addAll(_buildColumnWeights(_cols));
    _scratchWeightTotal = _rows * _colWeights.fold(0.0, (a, b) => a + b);
    _scratchWeightHit = 0.0;
    _revealTriggered = false;
  }

  List<double> _buildColumnWeights(int cols) {
    if (cols <= 1) return [1.4];
    final weights = <double>[];
    for (var i = 0; i < cols; i++) {
      final t = i / (cols - 1);
      final weight = 1.6 - (0.6 * t); // left-heavy: 1.6 → 1.0
      weights.add(weight);
    }
    return weights;
  }

  void _addPoint(Offset position) {
    _points.add(position);
    if (_cols > 0 && _rows > 0) {
      final col = (position.dx / widget.cellSize).floor().clamp(0, _cols - 1);
      final row = (position.dy / widget.cellSize).floor().clamp(0, _rows - 1);
      final cellIndex = row * _cols + col;
      if (_scratchedCells.add(cellIndex)) {
        _scratchWeightHit += _colWeights[col];
      }
    }
    final ratio =
        _scratchWeightTotal == 0 ? 0.0 : _scratchWeightHit / _scratchWeightTotal;
    if (ratio >= widget.revealThreshold && !_revealTriggered) {
      setState(() => _revealTriggered = true);
      _shimmerController.stop();
      widget.onReveal();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _updateGrid(constraints.biggest);
        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: widget.backgroundColor,
                ),
              ),
              Positioned.fill(child: widget.child),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (details) => _addPoint(details.localPosition),
                  onPanUpdate: (details) => _addPoint(details.localPosition),
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _ScratchPainter(
                          points: _points,
                          overlayColor: widget.overlayColor,
                          borderRadius: widget.borderRadius,
                          label: widget.label,
                          labelStyle: widget.labelStyle,
                          textDirection: Directionality.of(context),
                          scratchRadius: widget.scratchRadius,
                          showLabel: widget.showLabel && !_revealTriggered,
                          overlayOpacity: widget.overlayOpacity,
                          shimmerValue: _shimmerController.value,
                          showShimmer: !_revealTriggered,
                        ),
                      );
                    },
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

class _ScratchPainter extends CustomPainter {
  final List<Offset> points;
  final Color overlayColor;
  final BorderRadius borderRadius;
  final String label;
  final TextStyle labelStyle;
  final TextDirection textDirection;
  final double scratchRadius;
  final bool showLabel;
  final double overlayOpacity;
  final double shimmerValue;
  final bool showShimmer;

  _ScratchPainter({
    required this.points,
    required this.overlayColor,
    required this.borderRadius,
    required this.label,
    required this.labelStyle,
    required this.textDirection,
    required this.scratchRadius,
    required this.showLabel,
    required this.overlayOpacity,
    required this.shimmerValue,
    required this.showShimmer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    canvas.saveLayer(rect, Paint());
    final paint = Paint()..color = overlayColor.withOpacity(overlayOpacity);
    canvas.drawRRect(rrect, paint);

    if (showShimmer && overlayOpacity > 0) {
      final shimmerOpacity = (0.35 * overlayOpacity).clamp(0.0, 1.0);
      final gradient = LinearGradient(
        begin: Alignment(-1.2 + 2.4 * shimmerValue, -0.8),
        end: Alignment(-0.2 + 2.4 * shimmerValue, 0.8),
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(shimmerOpacity),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
      final shimmerPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..blendMode = BlendMode.screen;
      canvas.drawRRect(rrect, shimmerPaint);
    }

    if (showLabel) {
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: textDirection,
      );
      textPainter.layout(maxWidth: size.width - 16);
      final textOffset = Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      );
      textPainter.paint(canvas, textOffset);
    }

    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = scratchRadius * 2;
    for (final point in points) {
      canvas.drawCircle(point, scratchRadius, clearPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScratchPainter oldDelegate) {
    return oldDelegate.points.length != points.length ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.label != label ||
        oldDelegate.showLabel != showLabel ||
        oldDelegate.overlayOpacity != overlayOpacity ||
        oldDelegate.shimmerValue != shimmerValue ||
        oldDelegate.showShimmer != showShimmer;
  }
}
