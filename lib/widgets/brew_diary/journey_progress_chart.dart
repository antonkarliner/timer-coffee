import 'dart:collection';
import 'dart:math' as math;

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/visual/color_schemes.dart';
import 'package:flutter/material.dart';

@immutable
class JourneyChartPoint {
  const JourneyChartPoint({required this.attemptIndex, required this.entry});

  final int attemptIndex;
  final DiaryEntry entry;

  double? get rating => entry.rating;
  bool get isEvaluated => rating != null;
  String get attemptLabel => '#${attemptIndex + 1}';
  String? get ratingLabel => rating?.toStringAsFixed(1);
}

enum JourneyRatingLabelPlacement { above, below }

@immutable
class JourneyChartConnection {
  const JourneyChartConnection({
    required this.fromAttemptIndex,
    required this.toAttemptIndex,
  });

  final int fromAttemptIndex;
  final int toAttemptIndex;
}

/// Test-visible chart model that keeps missing evaluations explicit.
@immutable
class JourneyChartData {
  JourneyChartData._({
    required List<JourneyChartPoint> points,
    required List<JourneyChartConnection> connections,
    required this.bestAttemptIndex,
  }) : points = UnmodifiableListView(points),
       connections = UnmodifiableListView(connections);

  factory JourneyChartData.fromEntries(Iterable<DiaryEntry> source) {
    final entries = source.toList()
      ..sort((a, b) {
        final byDate = a.createdAt.compareTo(b.createdAt);
        if (byDate != 0) return byDate;
        return a.statUuid.compareTo(b.statUuid);
      });
    final points = [
      for (var index = 0; index < entries.length; index++)
        JourneyChartPoint(attemptIndex: index, entry: entries[index]),
    ];
    final rated = points.where((point) => point.isEvaluated).toList();
    final connections = [
      for (var index = 1; index < rated.length; index++)
        JourneyChartConnection(
          fromAttemptIndex: rated[index - 1].attemptIndex,
          toAttemptIndex: rated[index].attemptIndex,
        ),
    ];

    JourneyChartPoint? best;
    for (final point in rated) {
      if (best == null || point.rating! >= best.rating!) {
        best = point;
      }
    }

    return JourneyChartData._(
      points: points,
      connections: connections,
      bestAttemptIndex: best?.attemptIndex,
    );
  }

  final UnmodifiableListView<JourneyChartPoint> points;
  final UnmodifiableListView<JourneyChartConnection> connections;
  final int? bestAttemptIndex;

  int get evaluatedCount => points.where((point) => point.isEvaluated).length;

  JourneyRatingLabelPlacement ratingLabelPlacementFor(int attemptIndex) {
    if (attemptIndex == bestAttemptIndex) {
      return JourneyRatingLabelPlacement.below;
    }
    final rated = points.where((point) => point.isEvaluated).toList();
    final ratedIndex = rated.indexWhere(
      (point) => point.attemptIndex == attemptIndex,
    );
    if (ratedIndex <= 0 || ratedIndex >= rated.length - 1) {
      return JourneyRatingLabelPlacement.above;
    }
    final previous = rated[ratedIndex - 1].rating!;
    final current = rated[ratedIndex].rating!;
    final next = rated[ratedIndex + 1].rating!;
    return current <= previous && current <= next
        ? JourneyRatingLabelPlacement.below
        : JourneyRatingLabelPlacement.above;
  }
}

class JourneyProgressChart extends StatelessWidget {
  const JourneyProgressChart({
    super.key,
    required this.methodName,
    required this.entries,
    required this.scrollController,
  });

  final String methodName;
  final List<DiaryEntry> entries;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final data = JourneyChartData.fromEntries(entries);
    final chartSummary = loc.journeyProgressChartLabel(
      methodName,
      data.evaluatedCount,
      data.points.length,
    );
    final tastePoints = data.points.where(
      (point) => point.isEvaluated && point.entry.tasteBalance != null,
    );
    final hasTastePoints = tastePoints.isNotEmpty;
    final chartSemantics = [
      chartSummary,
      for (final point in data.points)
        [
          '${point.attemptLabel}: '
              '${point.ratingLabel ?? loc.brewDiaryNotRated}',
          if (point.entry.tasteBalance != null)
            _tasteLabel(loc, point.entry.tasteBalance!),
        ].join(', '),
    ].join('. ');
    final labelStyle =
        theme.textTheme.labelSmall ??
        AppTextStyles.badge.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final scaledLabelHeight = textScaler.scale(labelStyle.fontSize ?? 11);
    final chartHeight =
        AppSpacing.xxl * 5 +
        math.max(0, scaledLabelHeight - (labelStyle.fontSize ?? 11)) * 2;

    return Semantics(
      container: true,
      label: chartSemantics,
      image: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: AppSpacing.xl,
                  height: AppSpacing.sm,
                  child: CustomPaint(
                    painter: _DashedLegendPainter(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '$methodName${loc.summarySeparator}'
                    '${loc.journeyEvaluatedCount(data.evaluatedCount, data.points.length)}',
                    key: const ValueKey('journeyProgressChartContext'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (data.evaluatedCount == 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                loc.journeyEvaluatedBrewCount(0),
                key: const ValueKey('journeyProgressUnratedState'),
                textAlign: TextAlign.center,
                style: labelStyle.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (hasTastePoints) ...[
              const SizedBox(height: AppSpacing.sm),
              _TasteLegend(labelStyle: labelStyle),
            ],
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final minimumWidth = constraints.maxWidth;
                final pointSpacing = math.max(
                  AppSpacing.xl,
                  textScaler.scale(AppSpacing.lg) + AppSpacing.sm,
                );
                final historyWidth = data.points.length <= 1
                    ? minimumWidth
                    : AppSpacing.xxl * 2 +
                          (data.points.length - 1) * pointSpacing;
                final chartWidth = math.max(minimumWidth, historyWidth);
                return SingleChildScrollView(
                  key: const ValueKey('journeyProgressChartScroll'),
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    height: chartHeight,
                    child: CustomPaint(
                      key: const ValueKey('journeyProgressChartPaint'),
                      painter: JourneyProgressPainter(
                        data: data,
                        colorScheme: theme.colorScheme,
                        labelStyle: labelStyle,
                        bestCupLabel: loc.journeyBestCup,
                        textDirection: Directionality.of(context),
                        textScaler: textScaler,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _tasteLabel(AppLocalizations loc, int tasteBalance) =>
      switch (tasteBalance) {
        -1 => loc.tasteSour,
        0 => loc.tasteBalanced,
        _ => loc.tasteBitter,
      };
}

class _TasteLegend extends StatelessWidget {
  const _TasteLegend({required this.labelStyle});

  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    return Wrap(
      key: const ValueKey('journeyTasteLegend'),
      alignment: WrapAlignment.center,
      spacing: AppSpacing.base,
      runSpacing: AppSpacing.xs,
      children: [
        _TasteLegendItem(
          color: AppSemanticColors.taste(-1, brightness).background,
          label: loc.tasteSour,
          labelStyle: labelStyle,
        ),
        _TasteLegendItem(
          color: AppSemanticColors.taste(0, brightness).background,
          label: loc.tasteBalanced,
          labelStyle: labelStyle,
        ),
        _TasteLegendItem(
          color: AppSemanticColors.taste(1, brightness).background,
          label: loc.tasteBitter,
          labelStyle: labelStyle,
        ),
      ],
    );
  }
}

class _TasteLegendItem extends StatelessWidget {
  const _TasteLegendItem({
    required this.color,
    required this.label,
    required this.labelStyle,
  });

  final Color color;
  final String label;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, size: AppSpacing.sm, color: color),
      const SizedBox(width: AppSpacing.xs),
      Text(label, style: labelStyle),
    ],
  );
}

/// Resolved text bounds and placements in chart-local coordinates.
@immutable
class JourneyChartLabelLayout {
  JourneyChartLabelLayout({
    required Map<int, Rect> ratingLabelRects,
    required Map<int, JourneyRatingLabelPlacement> ratingLabelPlacements,
    required this.bestCupRect,
    required this.bestMarkerRect,
  }) : ratingLabelRects = Map.unmodifiable(ratingLabelRects),
       ratingLabelPlacements = Map.unmodifiable(ratingLabelPlacements);

  final Map<int, Rect> ratingLabelRects;
  final Map<int, JourneyRatingLabelPlacement> ratingLabelPlacements;
  final Rect? bestCupRect;
  final Rect? bestMarkerRect;
}

/// Public for focused painter configuration assertions in widget tests.
class JourneyProgressPainter extends CustomPainter {
  const JourneyProgressPainter({
    required this.data,
    required this.colorScheme,
    required this.labelStyle,
    required this.bestCupLabel,
    required this.textDirection,
    required this.textScaler,
  });

  final JourneyChartData data;
  final ColorScheme colorScheme;
  final TextStyle labelStyle;
  final String bestCupLabel;
  final TextDirection textDirection;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    final plotLeft = AppSpacing.xl;
    final plotRight = size.width - AppSpacing.base;
    final plotTop = _plotTop;
    final attemptLane = _attemptLane(size);
    final ratedBottom = _ratedBottom(size);
    final labels = layoutLabels(size);
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.55)
      ..strokeWidth = AppStroke.border;
    final labelColor = colorScheme.onSurfaceVariant;

    for (var rating = 1; rating <= 5; rating++) {
      final y = _ratingY(rating.toDouble(), plotTop, ratedBottom);
      canvas.drawLine(Offset(plotLeft, y), Offset(plotRight, y), gridPaint);
      final painter = _textPainter(
        '$rating',
        labelStyle.copyWith(color: labelColor),
      );
      painter.paint(
        canvas,
        Offset(
          plotLeft - painter.width - AppSpacing.sm,
          y - painter.height / 2,
        ),
      );
    }

    final attemptDividerPaint = Paint()
      ..color = colorScheme.outlineVariant
      ..strokeWidth = AppStroke.border;
    canvas.drawLine(
      Offset(plotLeft, attemptLane - AppSpacing.sm),
      Offset(plotRight, attemptLane - AppSpacing.sm),
      attemptDividerPaint,
    );

    if (data.points.isEmpty) return;
    final ratedPositions = _ratedPositions(size);
    final attemptPositions = {
      for (final point in data.points)
        point.attemptIndex: Offset(
          _pointX(point.attemptIndex, size),
          attemptLane,
        ),
    };

    final connectionPaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = AppStroke.focus
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final connection in data.connections) {
      _drawDashedLine(
        canvas,
        ratedPositions[connection.fromAttemptIndex]!,
        ratedPositions[connection.toAttemptIndex]!,
        connectionPaint,
      );
    }

    final filledPaint = Paint()..style = PaintingStyle.fill;
    final hollowPaint = Paint()
      ..color = colorScheme.onSurfaceVariant
      ..strokeWidth = AppStroke.focus
      ..style = PaintingStyle.stroke;
    for (final point in data.points) {
      final attemptPosition = attemptPositions[point.attemptIndex]!;
      if (!point.isEvaluated) {
        canvas.drawCircle(attemptPosition, AppSpacing.sm / 2, hollowPaint);
      }
      final attemptPainter = _textPainter(
        point.attemptLabel,
        labelStyle.copyWith(color: labelColor),
      );
      _paintCenteredClamped(
        canvas,
        attemptPainter,
        centerX: attemptPosition.dx,
        y: attemptLane + AppSpacing.xs,
        left: plotLeft,
        right: plotRight,
      );

      final ratedPosition = ratedPositions[point.attemptIndex];
      if (ratedPosition == null) continue;
      filledPaint.color = colorForPoint(point);
      canvas.drawCircle(ratedPosition, AppSpacing.sm / 2, filledPaint);
      final ratingPainter = _ratingTextPainter(point);
      _paintWithKnockout(
        canvas,
        ratingPainter,
        labels.ratingLabelRects[point.attemptIndex]!,
      );
    }

    final bestMarkerRect = labels.bestMarkerRect;
    if (bestMarkerRect != null) {
      canvas.drawCircle(
        bestMarkerRect.center,
        bestMarkerRect.width / 2,
        hollowPaint..color = colorScheme.primary,
      );
      _bestCupTextPainter(size).paint(canvas, labels.bestCupRect!.topLeft);
    }
  }

  /// Public for focused label-layout assertions in widget tests.
  JourneyChartLabelLayout layoutLabels(Size size) {
    final positions = _ratedPositions(size);
    final bestPosition = positions[data.bestAttemptIndex];
    Rect? bestCupRect;
    Rect? bestMarkerRect;
    if (bestPosition != null) {
      final painter = _bestCupTextPainter(size);
      final y = (bestPosition.dy - painter.height - AppSpacing.sm).clamp(
        0.0,
        math.max(0.0, _ratedBottom(size) - painter.height),
      );
      bestCupRect = _centeredClampedRect(
        painter,
        bestPosition.dx,
        y.toDouble(),
        size,
      );
      bestMarkerRect = Rect.fromCircle(
        center: bestPosition,
        radius: AppSpacing.sm,
      );
    }

    final rects = <int, Rect>{};
    final placements = <int, JourneyRatingLabelPlacement>{};
    for (final point in data.points) {
      final position = positions[point.attemptIndex];
      if (position == null) continue;
      final painter = _ratingTextPainter(point);
      var placement = data.ratingLabelPlacementFor(point.attemptIndex);
      Rect ratingRect(JourneyRatingLabelPlacement placement) {
        final below = placement == JourneyRatingLabelPlacement.below;
        final preferredY = below
            ? position.dy + AppSpacing.sm
            : position.dy - painter.height - AppSpacing.sm;
        final bottom = below
            ? _attemptLane(size) - AppSpacing.sm
            : _ratedBottom(size);
        final y = preferredY.clamp(
          AppSpacing.xs,
          math.max(AppSpacing.xs, bottom - painter.height),
        );
        return _centeredClampedRect(painter, position.dx, y.toDouble(), size);
      }

      var rect = ratingRect(placement);
      // The knockout extends beyond the text; reserve that space as well.
      if (placement == JourneyRatingLabelPlacement.above &&
          bestCupRect != null &&
          rect.inflate(AppSpacing.xs / 2).overlaps(bestCupRect)) {
        placement = JourneyRatingLabelPlacement.below;
        rect = ratingRect(placement);
      }
      rects[point.attemptIndex] = rect;
      placements[point.attemptIndex] = placement;
    }
    return JourneyChartLabelLayout(
      ratingLabelRects: rects,
      ratingLabelPlacements: placements,
      bestCupRect: bestCupRect,
      bestMarkerRect: bestMarkerRect,
    );
  }

  double get _plotTop =>
      AppSpacing.xl +
      textScaler.scale(labelStyle.fontSize ?? 11) +
      AppSpacing.sm;

  double _attemptLane(Size size) => size.height - AppSpacing.xl;

  double _ratedBottom(Size size) => _attemptLane(size) - AppSpacing.xl;

  double _pointX(int index, Size size) {
    final left = AppSpacing.xl;
    final right = size.width - AppSpacing.base;
    return data.points.length == 1
        ? (left + right) / 2
        : left + (right - left) * index / (data.points.length - 1);
  }

  Map<int, Offset> _ratedPositions(Size size) => {
    for (final point in data.points)
      if (point.isEvaluated)
        point.attemptIndex: Offset(
          _pointX(point.attemptIndex, size),
          _ratingY(
            point.rating!.clamp(1, 5).toDouble(),
            _plotTop,
            _ratedBottom(size),
          ),
        ),
  };

  TextStyle get _ratingLabelStyle => labelStyle.copyWith(
    color: colorScheme.primary,
    fontWeight: FontWeight.w600,
  );

  TextPainter _ratingTextPainter(JourneyChartPoint point) =>
      _textPainter(point.ratingLabel!, _ratingLabelStyle);

  TextPainter _bestCupTextPainter(Size size) => _textPainter(
    '★ $bestCupLabel',
    _ratingLabelStyle,
    maxLines: 1,
    maxWidth: math.max(0.0, size.width - AppSpacing.base - AppSpacing.xl),
    ellipsis: '…',
  );

  Rect _centeredClampedRect(
    TextPainter painter,
    double centerX,
    double y,
    Size size,
  ) {
    final left = AppSpacing.xl;
    final right = size.width - AppSpacing.base;
    final x = (centerX - painter.width / 2).clamp(
      left,
      math.max(left, right - painter.width),
    );
    return Offset(x.toDouble(), y) & painter.size;
  }

  /// Public for focused semantic-color assertions in widget tests.
  Color colorForPoint(JourneyChartPoint point) {
    final tasteBalance = point.entry.tasteBalance;
    if (tasteBalance == null) return colorScheme.primary;
    return AppSemanticColors.taste(
      tasteBalance,
      colorScheme.brightness,
    ).background;
  }

  TextPainter _textPainter(
    String text,
    TextStyle style, {
    int? maxLines,
    double? maxWidth,
    String? ellipsis,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: maxLines,
      ellipsis: ellipsis,
    );
    painter.layout(maxWidth: maxWidth ?? double.infinity);
    return painter;
  }

  void _paintCenteredClamped(
    Canvas canvas,
    TextPainter painter, {
    required double centerX,
    required double y,
    required double left,
    required double right,
  }) {
    final preferredX = centerX - painter.width / 2;
    final x = preferredX.clamp(left, math.max(left, right - painter.width));
    painter.paint(canvas, Offset(x.toDouble(), y));
  }

  void _paintWithKnockout(Canvas canvas, TextPainter painter, Rect rect) {
    final background = RRect.fromRectAndRadius(
      rect.inflate(AppSpacing.xs / 2),
      const Radius.circular(AppSpacing.xs),
    );
    canvas.drawRRect(
      background,
      Paint()
        ..color = colorScheme.surface
        ..style = PaintingStyle.fill,
    );
    painter.paint(canvas, rect.topLeft);
  }

  double _ratingY(double rating, double top, double bottom) =>
      top + (5 - rating) / 4 * (bottom - top);

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final vector = end - start;
    final distance = vector.distance;
    if (distance == 0) return;
    final direction = vector / distance;
    var travelled = 0.0;
    while (travelled < distance) {
      final dashEnd = math.min(travelled + AppSpacing.sm, distance);
      canvas.drawLine(
        start + direction * travelled,
        start + direction * dashEnd,
        paint,
      );
      travelled = dashEnd + AppSpacing.xs;
    }
  }

  @override
  bool shouldRepaint(covariant JourneyProgressPainter oldDelegate) =>
      oldDelegate.data.points != data.points ||
      oldDelegate.data.connections != data.connections ||
      oldDelegate.data.bestAttemptIndex != data.bestAttemptIndex ||
      oldDelegate.colorScheme != colorScheme ||
      oldDelegate.labelStyle != labelStyle ||
      oldDelegate.bestCupLabel != bestCupLabel ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.textScaler != textScaler;
}

class _DashedLegendPainter extends CustomPainter {
  const _DashedLegendPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = AppStroke.focus
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    final dashWidth = AppSpacing.sm;
    for (var x = 0.0; x < size.width; x += dashWidth + AppSpacing.xs) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dashWidth, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLegendPainter oldDelegate) =>
      oldDelegate.color != color;
}
