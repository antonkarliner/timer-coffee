import 'dart:async';

import 'package:flutter/material.dart';
import 'package:coffee_timer/theme/design_tokens.dart';

/// A full-screen loading overlay used while a background operation (the AI
/// label scan, or a bean save) is in progress.
///
/// It always dims and blocks the entire area it is stacked over. Callers
/// must make sure any modal route sitting above that area (a bottom sheet,
/// a dialog) has already been dismissed before this becomes visible —
/// otherwise it will render underneath that route instead of over it.
///
/// Everything shown here must be driven by something that actually
/// happened: [detail] should describe the real stage of work in progress,
/// and [reassurance] (revealed only after a real amount of wall-clock time
/// has passed) simply lets the user know the app hasn't hung. Neither is a
/// fabricated percentage, countdown, or progress bar.
class LoadingOverlay extends StatefulWidget {
  /// Primary heading, e.g. "Analyzing" or "Saving…".
  final String label;

  /// Optional secondary line naming the current real stage of work, e.g.
  /// "Reading the label…". Rebuilds live as the caller's stage changes.
  final String? detail;

  /// Optional reassurance line shown once the wait crosses a threshold, to
  /// confirm the app is still working rather than hung. Purely a function
  /// of elapsed time — never implies how much longer remains.
  final String? reassurance;

  /// How long to wait before revealing [reassurance]. Ignored if
  /// [reassurance] is null.
  final Duration reassuranceDelay;

  const LoadingOverlay({
    super.key,
    required this.label,
    this.detail,
    this.reassurance,
    this.reassuranceDelay = const Duration(seconds: 10),
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  Timer? _reassuranceTimer;
  bool _showReassurance = false;

  @override
  void initState() {
    super.initState();
    _scheduleReassurance();
  }

  @override
  void didUpdateWidget(covariant LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reassurance != widget.reassurance) {
      _reassuranceTimer?.cancel();
      _showReassurance = false;
      _scheduleReassurance();
    }
  }

  void _scheduleReassurance() {
    if (widget.reassurance == null) return;
    _reassuranceTimer = Timer(widget.reassuranceDelay, () {
      if (mounted) setState(() => _showReassurance = true);
    });
  }

  @override
  void dispose() {
    _reassuranceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Deliberately NOT a Positioned — callers stack this inside a Semantics
    // wrapper, and Positioned requires a Stack as its direct widget-tree
    // parent. A plain Material under bounded Stack constraints already
    // expands to fill the available area (matching the scrollable content
    // it sits above), which is all that's needed here.
    return Material(
      color: colorScheme.scrim.withValues(alpha: 0.55),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            color: colorScheme.surfaceContainerHigh,
            elevation: 6.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: AppIconSize.large,
                    height: AppIconSize.large,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.0,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.detail != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.detail!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (_showReassurance && widget.reassurance != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        widget.reassurance!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
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
